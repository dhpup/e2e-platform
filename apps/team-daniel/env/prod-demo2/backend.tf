terraform {
  backend "local" {
    path = "../env/prod-demo2/terraform.tfstate"
  }
}
