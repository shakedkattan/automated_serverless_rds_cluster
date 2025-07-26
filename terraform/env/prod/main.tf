locals {
  mysql_list    = ["kore", "test1"]
  postgres_list = ["payments", "analytics", "test2"]

  # Map DB name
  engine_map = merge(
    { for name in local.mysql_list    : name => { engine = "mysql" } },
    { for name in local.postgres_list : name => { engine = "postgres" } }
  )


  shared_settings = {
    instance_class       = "db.t3.micro"
    username             = "master_user"
    password             = "master_password"
    db_subnet_group_name = aws_db_subnet_group.rds.name
    security_group_ids   = [aws_security_group.rds.id]
    allocated_storage    = 20
  }

  rds_customs = {
    "payments-db" = {
      instance_class = "db.t3.small"
    },
    "analytics-db" = {
      allocated_storage = 21
    }
  }


  rds_list = concat(local.mysql_list, local.postgres_list)
  rds_definitions = {
    for name in local.rds_list :
    name => merge(
      local.shared_settings,
      local.engine_map[name],
      lookup(local.rds_customs, name, {}),
      { name = name }
    )
  }
}

module "rds_instances" {
  for_each = local.rds_definitions

  source = "git::https://github.com/shakedkattan/automated_serverless_rds_cluster.git//terraform/modules/rds?ref=main"

  name                 = each.value.name
  engine               = each.value.engine
  instance_class       = each.value.instance_class
  username             = each.value.username
  password             = each.value.password
  db_subnet_group_name = each.value.db_subnet_group_name
  security_group_ids   = each.value.security_group_ids
  allocated_storage    = each.value.allocated_storage
}
