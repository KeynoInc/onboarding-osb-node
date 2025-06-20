import fs from 'node:fs'
import { promisify } from 'util'
import { plainToInstance } from 'class-transformer'

import { BrokerService } from '../broker.service'
import { Catalog } from '../../models/catalog.model'
import { CreateServiceInstanceResponse } from '../../models/response/create-service-instance-response.model'
import { CreateServiceInstanceRequest } from '../../models/create-service-instance-request.model'

import { ServiceDefinition } from '../../models/service-definition.model'
import { UpdateStateRequest } from '../../models/update-state-request.model'
import { ServiceInstanceStateResponse } from '../../models/response/service-instance-state-response.model'
import logger from '../../utils/logger'
import { ServiceInstance } from '../../db/entities/service-instance.entity'
import BrokerUtil from '../../utils/brokerUtil'
import { CatalogUtil } from '../../utils/catalogUtil'
import { ServiceInstanceStatus } from '../../enums/service-instance-status'
import { OperationState } from '../../enums/operation-state'
import AppDataSource from '../../db/data-source'
import { ServiceInstanceLastOperationResponse } from '../../models/response/service-instance-last-operation-response.model'

export class BrokerServiceImpl implements BrokerService {
  dashboardUrl: string = process.env.DASHBOARD_URL || 'http://localhost:8080'
  private catalog: Catalog
  private static readonly INSTANCE_STATE = 'state'
  private static readonly DISPLAY_NAME = 'displayName'
  private static readonly PROVISION_STATUS_API = '/provision_status?type='
  private static readonly INSTANCE_ID = '&instance_id='

  constructor() {
    this.catalog = new Catalog([])
  }

  public async importCatalog(file: Express.Multer.File): Promise<string> {
    const readFile = promisify(fs.readFile)

    try {
      const data = await readFile(file.path, { encoding: 'utf8' })

      return this.importCatalogFromJson(data)
    } catch (error) {
      logger.error(`Failed to import catalog: ${error}`)
      throw error
    }
  }

  public importCatalogFromAssets(): string {
    const catalogPath =
      process.env['NODE_ENV'] === 'development'
        ? './src/assets/data/catalog.json'
        : './dist/assets/data/catalog.json'
    try {
      //TODO: Make this path configurable using environment variables

      const data = fs.readFileSync(catalogPath, 'utf8')

      // Remove BOM (Byte Order Mark) if present
      // Assuming that this file is always a single service catalog
      const cleanData = data.replace(/^\uFEFF/, '')
      const catalogJson = JSON.parse(cleanData)
      const serviceDefinitionsJSON = JSON.stringify({ services: [catalogJson] })

      return this.importCatalogFromJson(serviceDefinitionsJSON)
    } catch (error) {
      logger.error(
        `Failed to get catalog from asset path '${catalogPath}', error: '${error}'`,
      )
      throw error
    }
  }

  public async getCatalog(): Promise<Catalog> {
    if (!this.catalog || !this.catalog.getServiceDefinitions().length) {
      logger.warn('Catalog is empty, importing from assets...')
      this.importCatalogFromAssets()
    } else {
      logger.info('Catalog already loaded, returning existing catalog.')
    }
    return this.catalog
  }

  public async provision(
    instanceId: string,
    details: any,
    iamId: string,
    region: string,
  ): Promise<CreateServiceInstanceResponse> {
    try {
      const createServiceRequest = new CreateServiceInstanceRequest(details)
      createServiceRequest.instanceId = instanceId

      if (
        createServiceRequest.context &&
        createServiceRequest.context.platform === BrokerUtil.IBM_CLOUD
      ) {
        const plan = CatalogUtil.getPlan(
          this.catalog,
          createServiceRequest.service_id,
          createServiceRequest.plan_id,
        )

        if (!plan) {
          logger.error(
            `Plan id:${createServiceRequest.plan_id} does not belong to this service: ${createServiceRequest.service_id}`,
          )
          throw new Error(`Invalid plan id: ${createServiceRequest.plan_id}`)
        }

        //TODO: Check if the instanceId already exists but with different attributes then throw a 409 error, if not then skip the getServiceInstanceEntity method just return the found instance

        const serviceInstance = this.getServiceInstanceEntity(
          createServiceRequest,
          iamId,
          region,
        )

        const serviceInstanceRepository =
          AppDataSource.getRepository(ServiceInstance)
        const createdServiceInstance =
          await serviceInstanceRepository.save(serviceInstance)

        logger.info(
          `Service Instance created: instanceId: ${instanceId} status: ${serviceInstance.status} planId: ${plan.id}`,
        )

        const displayName = this.getServiceMetaDataByAttribute(
          BrokerServiceImpl.DISPLAY_NAME,
        )
        const responseUrl = `${process.env.DASHBOARD_URL}${BrokerServiceImpl.PROVISION_STATUS_API}${displayName ?? this.catalog.getServiceDefinitions()[0].name}${BrokerServiceImpl.INSTANCE_ID}${instanceId}`

        logger.info(
          `Provisioning response URL: ${responseUrl} for instanceId: ${instanceId}`,
        )

        return plainToInstance(CreateServiceInstanceResponse, {
          dashboardUrl: responseUrl,
          operation: `${createdServiceInstance.id}`,
        })
      } else {
        logger.error(
          `Unidentified platform: ${createServiceRequest.context?.platform}`,
        )
        throw new Error(
          `Invalid platform: ${createServiceRequest.context?.platform}`,
        )
      }
    } catch (error) {
      logger.error('Error provisioning service instance:', error)
      throw new Error('Error provisioning service instance')
    }
  }

  public async deprovision(instanceId: string): Promise<boolean> {
    try {
      const serviceInstanceRepository =
        AppDataSource.getRepository(ServiceInstance)

      const serviceInstance = await serviceInstanceRepository.findOne({
        where: { instanceId },
      })
      if (!serviceInstance) {
        throw new Error(`Service instance with ID ${instanceId} not found`)
      }

      logger.info(`Deprovisioning service instance with ID: ${instanceId}`)
      await serviceInstanceRepository
        .merge(serviceInstance, {
          status: ServiceInstanceStatus.DEPROVISIONING,
          updateDate: new Date(),
        })
        .save()

      logger.info(
        `Service instance with ID: ${instanceId} marked as DEPROVISIONING`,
      )
      return true
    } catch (error) {
      logger.error('Error deprovisioning service instance:', error)
      throw new Error('Error deprovisioning service instance')
    }
  }

  private getServiceMetaDataByAttribute(attribute: string): string | null {
    const service = this.catalog.services[0]

    if (service?.metadata) {
      if (
        Object.hasOwn(service.metadata, attribute) &&
        service.metadata[attribute]
      ) {
        return service.metadata[attribute].toString()
      }
    }

    return null
  }

  public async lastOperation(
    instanceId: string,
    iamId: string,
    operationId: string,
  ): Promise<ServiceInstanceLastOperationResponse> {
    try {
      logger.info(
        `last_operation instanceId: ${instanceId} -- iamId: ${iamId} -- operationId: ${operationId}`,
      )

      const numericOperationId = Number(operationId)
      if (isNaN(numericOperationId)) {
        throw new Error(`Invalid operationId: ${operationId}`)
      }

      const serviceInstanceRepository =
        AppDataSource.getRepository(ServiceInstance)
      const serviceInstance = await serviceInstanceRepository.findOne({
        where: { instanceId, id: numericOperationId },
      })

      if (!serviceInstance) {
        throw new Error(`Service instance with ID ${instanceId} not found`)
      }

      logger.info(`Service instance found: ${JSON.stringify(serviceInstance)}`)

      let operationState = OperationState.IN_PROGRESS

      if (serviceInstance.status === ServiceInstanceStatus.ACTIVE) {
        operationState = OperationState.SUCCEEDED
      } else if (serviceInstance.status === ServiceInstanceStatus.FAILED) {
        operationState = OperationState.FAILED
      }

      logger.info(
        `Operation state for instance ${instanceId}: ${operationState}`,
      )

      const response = {
        [BrokerServiceImpl.INSTANCE_STATE]: operationState,
      }
      return response
    } catch (error) {
      throw new Error('Error fetching last operation', { cause: error })
    }
  }

  public async updateState(
    instanceId: string,
    updateStateRequest: UpdateStateRequest,
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    iamId: string,
  ): Promise<any> {
    try {
      const serviceInstanceRepository =
        AppDataSource.getRepository(ServiceInstance)
      const serviceInstance = await serviceInstanceRepository.findOne({
        where: { instanceId },
      })

      if (!serviceInstance) {
        throw new Error(`Service instance with ID ${instanceId} not found`)
      }

      await serviceInstanceRepository
        .merge(serviceInstance, {
          enabled: updateStateRequest.enabled,
          status: updateStateRequest.status,
          updateDate: new Date(),
        })
        .save()

      const response: ServiceInstanceStateResponse = {
        active: updateStateRequest.enabled || false,
        enabled: updateStateRequest.enabled || false,
        status: updateStateRequest.status || ServiceInstanceStatus.PROCESSING,
      }

      return response
    } catch (error) {
      logger.error('Error updating service instance state:', error)
      throw new Error('Error updating service instance state')
    }
  }

  public async getState(
    instanceId: string,
    iamId: string,
  ): Promise<ServiceInstanceStateResponse> {
    try {
      logger.info(
        `Getting state for instanceId: ${instanceId} and iamId: ${iamId}`,
      )

      const serviceInstanceRepository =
        AppDataSource.getRepository(ServiceInstance)
      const serviceInstance = await serviceInstanceRepository.findOne({
        where: { instanceId },
      })

      if (!serviceInstance) {
        throw new Error(`Service instance with ID ${instanceId} not found`)
      }

      const response: ServiceInstanceStateResponse = {
        active: serviceInstance?.status === ServiceInstanceStatus.ACTIVE,
        enabled: serviceInstance?.enabled ?? false,
        status: serviceInstance?.status ?? ServiceInstanceStatus.PROCESSING,
      }

      return response
    } catch (error) {
      logger.error('Error getting instance state:', error)
      throw new Error('Error getting instance state')
    }
  }

  private getServiceInstanceEntity(
    request: CreateServiceInstanceRequest,
    iamId: string,
    region: string,
  ): ServiceInstance {
    const instance = new ServiceInstance()
    instance.instanceId = request.instanceId ?? ''
    instance.name = request.context?.name ?? ''
    instance.serviceId = request.service_id
    instance.planId = request.plan_id
    instance.iamId = iamId
    instance.region = region
    instance.context = JSON.stringify(request.context)
    instance.parameters = JSON.stringify(request.parameters)
    instance.status = ServiceInstanceStatus.PROCESSING
    instance.enabled = true
    instance.createDate = new Date()
    instance.updateDate = new Date()

    return instance
  }

  private importCatalogFromJson(jsonString: string): string {
    try {
      const clean = jsonString.replace(/^\uFEFF/, '')
      const catalogJson = JSON.parse(clean)

      if (!catalogJson.services || !Array.isArray(catalogJson.services)) {
        throw new Error(
          'importCatalogFromJson: Invalid catalog format: "services" array is missing or not an array',
        )
      }

      const serviceDefinitions = catalogJson.services.map(
        (service: any) =>
          new ServiceDefinition(
            service.id,
            service.name,
            service.description,
            service.plans,
            service.bindable,
            service.plan_updateable,
            service.tags,
            service.metadata,
            service.requires,
            service.dashboard_client,
          ),
      )
      this.catalog = new Catalog(serviceDefinitions)
      logger.info(
        `importCatalogFromJson: Imported catalog: ${JSON.stringify(this.catalog)}`,
      )

      return catalogJson
    } catch (error) {
      logger.error(`importCatalogFromJson: Failed to import catalog: ${error}`)
      throw error
    }
  }
}
