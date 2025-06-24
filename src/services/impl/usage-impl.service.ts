import axios, { AxiosError, AxiosResponse } from 'axios'
import { MeteringPayload } from '../../models/metering-payload.model'
import { UsageService } from '../usage.service'
import logger from '../../utils/logger'
import { ServiceInstance } from '../../db/entities/service-instance.entity'
import AppDataSource from '../../db/data-source'
import { ServiceInstanceUsage } from '../../db/entities/service-instance-usage.entity'
import { plainToInstance } from 'class-transformer'

export class UsageServiceImpl implements UsageService {
  private usageEndpoint: string = process.env.USAGE_ENDPOINT || ''
  private iamEndpoint: string = process.env.IAM_ENDPOINT || ''
  private apiKey: string = process.env.METERING_API_KEY || ''

  private static readonly IAM_IDENTITY_TOKEN_PATH = '/identity/token'
  private static readonly IAM_GRANT_TYPE =
    'urn:ibm:params:oauth:grant-type:apikey'
  private static readonly USAGE_API_PATH =
    '/v4/metering/resources/{resource_id}/usage'

  public async sendUsageData(
    resourceId: string,
    meteringPayload: MeteringPayload,
  ): Promise<string> {
    try {
      if (meteringPayload.start === 0) {
        const instant = Date.now()
        meteringPayload.start = instant - 3600000
      }
      if (meteringPayload.end === 0) {
        const instant = Date.now()
        meteringPayload.end = instant
      }

      const iamAccessToken = await this.getIamAccessToken()
      const usageApiUrl = this.usageEndpoint.concat(
        UsageServiceImpl.USAGE_API_PATH.replace('{resource_id}', resourceId),
      )
      const response = await this.sendUsageDataToApi(
        usageApiUrl,
        iamAccessToken,
        [meteringPayload],
      )

      logger.info('Usage Metering response:', response.data)

      if (response.status === 202) {
        const responseJson = response.data.resources
        for (const resp of responseJson) {
          if (resp.status && resp.status !== 201) {
            logger.error(
              'ALERT: Error response from Metering Usage API:',
              JSON.stringify(resp),
            )
          } else {
            const serviceInstanceUsageRepository =
              AppDataSource.getRepository(ServiceInstanceUsage)
            const serviceInstanceUsage = new ServiceInstanceUsage()
            serviceInstanceUsage.instanceId =
              meteringPayload.resource_instance_id
            serviceInstanceUsage.statusCode = 202 // Accepted
            serviceInstanceUsage.checkStatusPartialUrl = resp.location
            serviceInstanceUsage.createDate = new Date()
            serviceInstanceUsage.updateDate = new Date()
            await serviceInstanceUsageRepository.save(serviceInstanceUsage)
            logger.info(
              `Usage data for instance ${meteringPayload.resource_instance_id} saved successfully.`,
            )
          }
        }
        return JSON.stringify(responseJson)
      } else {
        logger.error(
          'Error while sending USAGE data:',
          `response status code: ${response.status}`,
          `response body: ${JSON.stringify(response.data)}`,
        )
        return JSON.stringify(response.data)
      }
    } catch (error) {
      logger.error('Error sending usage data:', error)
      throw new Error('Error sending usage data')
    }
  }

  public async sendAllActiveInstancesUsageData(): Promise<string[]> {
    const sendActiveInstancesUsageDataResult =
      await this.sendActiveInstancesUsageData()

    const checkServiceInstanceUsageResult =
      await this.checkServiceInstanceUsage()

    return sendActiveInstancesUsageDataResult.concat(
      checkServiceInstanceUsageResult,
    )
  }

  private async sendActiveInstancesUsageData(): Promise<string[]> {
    const rawData = await AppDataSource.query(`
        SELECT si.*
        FROM service_instance si
        LEFT JOIN (
          SELECT DISTINCT instance_id
          FROM service_instance_usage
          WHERE status_code IN (200, 201, 202)
            AND create_date >= DATE_TRUNC('month', CURRENT_DATE)
            AND create_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
        ) siu_curr
          ON siu_curr.instance_id = si.instance_id
        WHERE si.status = 'ACTIVE'
          AND siu_curr.instance_id IS NULL`)

    const activeInstancesThisMonth: ServiceInstance[] = rawData.map(
      (data: any) =>
        plainToInstance<ServiceInstance, any>(ServiceInstance, {
          id: data.id,
          createDate: new Date(data.create_date),
          updateDate: new Date(data.update_date),
          version: data.version,
          instanceId: data.instance_id,
          name: data.name,
          iamId: data.iam_id,
          planId: data.plan_id,
          serviceId: data.service_id,
          enabled: data.enabled === 1,
          region: data.region,
          context: data.context,
          parameters: data.parameters,
          status: data.status,
        }),
    )

    if (activeInstancesThisMonth.length === 0) {
      logger.info('No active instances found to send usage data.')
      return []
    }

    const results: string[] = []
    for (const instance of activeInstancesThisMonth) {
      const startEndTime = new Date().getTime()
      const instanceMeteringPayload: MeteringPayload = {
        resource_instance_id: instance.instanceId,
        plan_id: instance.planId,
        region: instance.region,
        start: startEndTime, // default behavior.
        end: startEndTime, // default behavior.
        measured_usage: [
          {
            measure: 'INSTANCE',
            quantity: 1,
          },
        ],
      }

      try {
        const result = await this.sendUsageData(
          instance.serviceId,
          instanceMeteringPayload,
        )
        results.push(result)
      } catch (error) {
        logger.error(
          `Error sending usage data for instance ${instance.instanceId}:`,
          error,
        )
      }
    }
    logger.info('All active instances usage data sent successfully.')
    return results
  }

  private async checkServiceInstanceUsage(): Promise<string> {
    const serviceInstanceUsageRepository =
      AppDataSource.getRepository(ServiceInstanceUsage)

    const pendingServiceInstanceUsage =
      await serviceInstanceUsageRepository.find({
        where: {
          statusCode: 202,
        },
      })

    const iamAccessToken = await this.getIamAccessToken()

    for (const usage of pendingServiceInstanceUsage) {
      const result = await this.getServiceInstanceUsageStatus(
        iamAccessToken,
        usage,
      )

      usage.statusCode = result.statusCode
      usage.statusResponse = result.statusResponse
      usage.updateDate = new Date()

      await serviceInstanceUsageRepository.save(usage)
    }

    return JSON.stringify(pendingServiceInstanceUsage)
  }

  private async getServiceInstanceUsageStatus(
    token: string,
    serviceInstanceUsage: ServiceInstanceUsage,
  ): Promise<{ statusCode: number; statusResponse: Record<string, any> }> {
    try {
      const url = this.usageEndpoint.concat(
        serviceInstanceUsage.checkStatusPartialUrl,
      )
      logger.info('Sending usage data to API: ', url)
      const response = await axios.get(url, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      })
      logger.info(
        `Usage status code: ${response.status} -- data: ${JSON.stringify(response.data)}`,
      )
      const details = response.data?.details ?? {}
      return {
        statusCode: details.state === 'rated' ? 200 : 202,
        statusResponse: details,
      }
    } catch (error) {
      const axiosError = error as AxiosError

      if (axiosError.response) {
        logger.error('Failed with status:', axiosError.response.status)
        logger.error('Failed with response:', axiosError.response.data)
      }
      throw error
    }
  }

  private async sendUsageDataToApi(
    url: string,
    token: string,
    data: MeteringPayload[],
  ): Promise<AxiosResponse> {
    try {
      logger.info('Sending usage data to API: ', url)
      const response = await axios.post(url, data, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      })
      return response
    } catch (error) {
      const axiosError = error as AxiosError

      if (axiosError.response) {
        logger.error('Failed with status:', axiosError.response.status)
        logger.error('Failed with response:', axiosError.response.data)
      }
      throw error
    }
  }

  private async getIamAccessToken(): Promise<string> {
    const iamUrl = `${this.iamEndpoint}${UsageServiceImpl.IAM_IDENTITY_TOKEN_PATH}`
    const response = await axios.post(
      iamUrl,
      {},
      {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        params: {
          grant_type: UsageServiceImpl.IAM_GRANT_TYPE,
          apikey: this.apiKey,
        },
      },
    )

    if (response?.data?.access_token) {
      logger.info('Token retrieved successfully..')
      return response.data.access_token
    } else {
      throw new Error('Failed to retrieve IAM access token')
    }
  }
}
