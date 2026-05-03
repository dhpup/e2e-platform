terraform {
  backend "local" {
    path = "../env/prod-demo1/terraform.tfstate"
  }
}
