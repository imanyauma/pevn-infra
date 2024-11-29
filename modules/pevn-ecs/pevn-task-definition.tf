# --- ECR ---

resource "aws_ecr_repository" "app" {
  name                 = "pevn-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "demo_app_repo_url" {
  value = aws_ecr_repository.app.repository_url
}

# --- ECS Task Definition ---

resource "aws_ecs_task_definition" "app" {
  family             = "demo-app"
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_exec_role.arn
  network_mode       = "awsvpc"
  cpu                = 256
  memory             = 256

  container_definitions = jsonencode([{
    name         = "pevn-backend",
    image        = "${aws_ecr_repository.app.repository_url}:latest",
    essential    = true,
    portMappings = [{ containerPort = 3000, hostPort = 3000 }],

    environment = [
      { name = "EXAMPLE", value = "example" }
    ]
  }])
}