package main
import input as tfplan

########################
# Parameters for Policy
########################

# acceptable score for automated authorization
max_deletes_allowed := 0

creates := [res | res:=tfplan.resource_changes[_]; res.change.actions[_] == "create"]

deletes := [res | res := tfplan.resource_changes[_]; res.change.actions[_] == "delete"]
  
modifies := [res | res:=tfplan.resource_changes[_]; res.change.actions[_] == "modify"]

#########
# Policy
#########

# If deletes resources exists
deny[msg] {
    total := count(deletes)
    total > max_deletes_allowed
    msg = sprintf("Deletes is not allowed, we need peer review. Total deletes: %v", [total])
}