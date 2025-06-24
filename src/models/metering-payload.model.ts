import { IsNotEmpty } from 'class-validator'
import { MeasuredUsage } from './measured-usage.model'

export class MeteringPayload {
  @IsNotEmpty()
  plan_id: string

  @IsNotEmpty()
  resource_instance_id: string

  @IsNotEmpty()
  start: number

  @IsNotEmpty()
  end: number

  @IsNotEmpty()
  region: string

  @IsNotEmpty()
  measured_usage: MeasuredUsage[]

  constructor(
    planId: string,
    resourceInstanceId: string,
    start: number,
    end: number,
    region: string,
    measuredUsage: MeasuredUsage[],
  ) {
    this.plan_id = planId
    this.resource_instance_id = resourceInstanceId
    this.start = start
    this.end = end
    this.region = region
    this.measured_usage = measuredUsage
  }

  toString(): string {
    return `MeteringPayload{planId='${this.plan_id}', instanceId='${this.resource_instance_id}', startTime='${this.start}', endTime=${this.end}, MeasuredUsage=${JSON.stringify(this.measured_usage)}}`
  }
}
