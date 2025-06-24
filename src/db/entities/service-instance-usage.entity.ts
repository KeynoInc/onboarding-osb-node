import { Entity, Column } from 'typeorm'
import { BaseEntity } from './base.entity'

@Entity({ name: 'service_instance_usage' })
export class ServiceInstanceUsage extends BaseEntity {
  @Column({ name: 'instance_id' })
  instanceId!: string

  @Column({ name: 'status_code', nullable: false })
  statusCode!: number

  @Column({ name: 'check_status_partial_url', nullable: false })
  checkStatusPartialUrl!: string

  @Column({ name: 'status_response', type: 'json', nullable: true })
  statusResponse?: Record<string, any> | null
}
