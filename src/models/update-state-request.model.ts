import {
  IsNotEmpty,
  IsString,
  IsOptional,
  IsBoolean,
  IsEnum,
} from 'class-validator'
import { Type } from 'class-transformer'
import { ServiceInstanceStatus } from '../enums/service-instance-status'

export class UpdateStateRequest {
  @IsNotEmpty()
  @IsBoolean()
  @Type(() => Boolean)
  enabled!: boolean

  @IsNotEmpty()
  @IsEnum(ServiceInstanceStatus)
  @Type(() => String)
  status!: ServiceInstanceStatus

  @IsOptional()
  @IsString()
  @Type(() => String)
  initiatorId?: string

  @IsOptional()
  @IsString()
  @Type(() => String)
  reasonCode?: string

  constructor(details: Partial<UpdateStateRequest>) {
    if (details) {
      Object.assign(this, details)
    }
  }
}
