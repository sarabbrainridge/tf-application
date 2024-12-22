variable "region_short_name" {
  type = string
  default = "cc"
}

variable "env" {
  default = "lab"
}

variable "vpc_id" {
  default = "vpc-0d918cd659e10ed48"
}

variable "subnet_ids" {
  type = list(string)
  //default = ["subnet-0f146bbb3a2ef15ab","subnet-005660fe40bce333e","subnet-084cbb2cbe9a38268","subnet-095163acd49f50bef","subnet-0064d63862535d237","subnet-09615ab32c0f4fbc0"]
  default = ["subnet-0f146bbb3a2ef15ab","subnet-005660fe40bce333e"]
}