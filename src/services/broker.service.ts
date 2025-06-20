import { Catalog } from '../models/catalog.model'
import { CreateServiceInstanceResponse } from '../models/response/create-service-instance-response.model'
import { ServiceInstanceLastOperationResponse } from '../models/response/service-instance-last-operation-response.model'
import { ServiceInstanceStateResponse } from '../models/response/service-instance-state-response.model'
import { UpdateStateRequest } from '../models/update-state-request.model'

export interface BrokerService {
  provision(
    instanceId: string,
    details: any,
    iamId: string,
    region: string,
  ): Promise<CreateServiceInstanceResponse>
  deprovision(
    instanceId: string,
    planId: string,
    serviceId: string,
    iamId: string,
  ): Promise<boolean>
  lastOperation(
    instanceId: string,
    iamId: string,
    operationId: string,
  ): Promise<ServiceInstanceLastOperationResponse>
  importCatalog(file: Express.Multer.File): Promise<string>
  importCatalogFromAssets(): string
  getCatalog(): Promise<Catalog>
  updateState(
    instanceId: string,
    updateData: UpdateStateRequest,
    iamId: string,
  ): Promise<ServiceInstanceStateResponse>
  getState(
    instanceId: string,
    iamId: string,
  ): Promise<ServiceInstanceStateResponse>
}
