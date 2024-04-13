package main
import input as tfplan

########################
# Parameters for Policy
########################

# acceptable score for automated authorization
blast_radius = 0

# weights assigned for each operation on each resource-type
weights = {
    "azurerm_kubernetes_cluster": {"delete": 100, "create": 20, "modify": 1},
    "azuread_application": {"delete": 10, "create": 1, "modify": 1}
}

# Consider exactly these resource types in calculations
resource_types = {"azurerm_kubernetes_cluster", "azuread_application","azurerm_virtual_machine"}


# Compute the score for a Terraform plan as the weighted sum of deletions, creations, modifications
score = s {
    all := [ x |
            some resource_type
            crud := weights[resource_type];
            del := crud["delete"] * num_deletes[resource_type];
            new := crud["create"] * num_creates[resource_type];
            mod := crud["modify"] * num_modifies[resource_type];
            x := del + new + mod
    ]
    s := sum(all)
}

####################
# Terraform Library
####################

# list of all resources of a given type
resources[resource_type] = all {
    some resource_type
    resource_types[resource_type]
    all := [name |
        name:= tfplan.resource_changes[_]
        name.type == resource_type
    ]
}

# number of creations of resources of a given type
num_creates[resource_type] = num {
    some resource_type
    resource_types[resource_type]
    all := resources[resource_type]
    creates := [res |  res:= all[_]; res.change.actions[_] == "create"]
    num := count(creates)
}


# number of deletions of resources of a given type
num_deletes[resource_type] = num {
    some resource_type
    resource_types[resource_type]
    all := resources[resource_type]
    deletions := [res |  res:= all[_]; res.change.actions[_] == "delete"]
    num := count(deletions)
}

# number of modifications to resources of a given type
num_modifies[resource_type] = num {
    some resource_type
    resource_types[resource_type]
    all := resources[resource_type]
    modifies := [res |  res:= all[_]; res.change.actions[_] == "update"]
    num := count(modifies)
}

#########
# Policy
#########

# If deletes exists
deny[msg] {

    deletes := [r | r := tfplan.resource_changes[_]; r.change.actions[_] == "delete"]    
    total := count(deletes)
    total > blast_radius
    msg = sprintf("Deletes is not allowed, we need peer review. Total deletes: %v", [total])
}