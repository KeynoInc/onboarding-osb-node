import { RequestHandler } from 'express'
import { createNamespace } from 'cls-hooked'
import { v4 as uuidV4 } from 'uuid'

export const ns = createNamespace('request')
export const requestContextMiddleware: RequestHandler = (req, res, next) => {
  ns.run(() => {
    ns.set('requestId', req.headers['requestId'] || uuidV4())
    next()
  })
}
