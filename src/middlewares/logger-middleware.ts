import { RequestHandler } from 'express'
import logger from '../utils/logger'
import { v4 as uuidV4 } from 'uuid'

export const loggerMiddleware: RequestHandler = (req, res, next) => {
  const requestId = uuidV4()
  req.headers['requestId'] = requestId // Attach requestId to the request object
  logger.info(`Request received: ${req.method}: ${req.url}`)
  next()
}
