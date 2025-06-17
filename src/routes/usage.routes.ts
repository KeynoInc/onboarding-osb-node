import { Router } from 'express'
import { UsageController } from '../controllers/usage.controller'
import { UsageServiceImpl } from '../services/impl/usage-impl.service'

export class UsageRoutes {
  static get routes(): Router {
    const router = Router()

    const service = new UsageServiceImpl()
    const controller = new UsageController(service)

    router.post('/metering/:resourceId/usage', controller.sendUsageData)

    router.post(
      '/metering/all-active-instances',
      controller.sendAllActiveInstancesUsageData,
    )

    return router
  }
}
