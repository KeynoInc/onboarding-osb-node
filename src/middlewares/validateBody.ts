// middlewares/validateBody.ts
import { plainToInstance } from 'class-transformer'
import { validate } from 'class-validator'
import type { Request, Response, NextFunction } from 'express'

export function validateBody<T>(cls: new (d: Partial<T>) => T) {
  return async (req: Request, res: Response, next: NextFunction) => {
    const dto = plainToInstance(cls, req.body)
    const errors = await validate(dto, {
      whitelist: true,
      forbidNonWhitelisted: true,
    })

    if (errors.length > 0) {
      const formatted = errors.flatMap(err =>
        Object.values(err.constraints || {}).map(msg => ({
          field: err.property,
          message: msg,
        })),
      )
      return res.status(400).json({ errors: formatted })
    }

    req.body = dto
    next()
  }
}
