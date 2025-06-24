import { MigrationInterface, QueryRunner } from 'typeorm'

export class Keyno1750778765517 implements MigrationInterface {
  name = 'Keyno1750778765517'

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "service_instance_usage" ("id" SERIAL NOT NULL, "instance_id" character varying NOT NULL, "status_code" INTEGER NOT NULL, "check_status_partial_url" character varying NOT NULL, status_response json NULL, "create_date" TIMESTAMP NOT NULL, "update_date" TIMESTAMP NOT NULL, CONSTRAINT "PK_b1d4cae4ddaaf4f4da7bb8062da" PRIMARY KEY ("id"))`,
    )
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "service_instance_usage"`)
  }
}
