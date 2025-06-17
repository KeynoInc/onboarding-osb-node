import winston from 'winston'
import { ns } from '../middlewares/request-context'

const levels = {
  error: 0,
  warn: 1,
  info: 2,
  http: 3,
  debug: 4,
}

const level = () => {
  const env = process.env.NODE_ENV || 'development'
  const isDevelopment = env === 'development'
  return (process.env.LOG_LEVEL ?? isDevelopment) ? 'debug' : 'http'
}

const colors = {
  error: 'red',
  warn: 'yellow',
  info: 'green',
  http: 'magenta',
  debug: 'white',
}

winston.addColors(colors)

const format = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss:ms' }),
  winston.format.colorize({ all: true }),
  winston.format.printf(info => {
    const requestId = ns.get('requestId')
    return `${info.timestamp} ${requestId} ${info.level}: ${info.message}`
  }),
)

const transports = [new winston.transports.Console()]

const logger = winston.createLogger({
  level: level(),
  levels,
  format,
  transports,
})

export default logger
