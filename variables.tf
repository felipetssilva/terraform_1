variable "rule_name1"{
  type=string
  description= "name for the security rule in the NSG"
}
variable "port_range1"{
  type=string
  description=" port range in the security rule in NSG "
}

variable "admin1"{
  type =string
  description="user name for the windows virtual machine vm1 "
}
variable "pass1"{
  type =string
  description="password for the windows virtual machine vm1"
}

variable "bastion_tags"{
  type =object({
    name = string
    reason =string
    
  })
}