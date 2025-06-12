import { IsOptional, IsString } from 'class-validator'

export class ServiceInstanceLastOperationResponse {
  @IsOptional()
  @IsString()
  state?: string

  constructor(data: Partial<ServiceInstanceLastOperationResponse>) {
    if (data) {
      Object.assign(this, data)
    }
  }
}
