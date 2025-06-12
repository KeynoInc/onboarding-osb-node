import { IsBoolean, IsOptional, IsNumber, IsString } from 'class-validator'
import { Expose } from 'class-transformer'

export class ServiceInstanceStateResponse {
  @IsOptional()
  @IsBoolean()
  active?: boolean

  @IsOptional()
  @IsBoolean()
  enabled?: boolean

  @IsOptional()
  @IsNumber()
  @Expose({ name: 'last_active' })
  lastActive?: number

  @IsOptional()
  @IsString()
  status?: string

  constructor(data: Partial<ServiceInstanceStateResponse>) {
    if (data) {
      Object.assign(this, data)
    }
  }
}
