rgHub=rg-ars-lab-hub
rgSpoke=rg-ars-lab-spoke
rgOnprem=rg-ars-lab-onprem
hubVngName=vng-hub-ars-lab
branchVngName=
arsName=ars-hub
peerName=csr-hub
nicSp1Vm1=sp1vm01-nic
nicHubVm1=mgmtvm01-nic
nicOnpremVm1=onpvm01-nic


# Show Public IPs
# az network public-ip show -g $rgHub -n $hubVngName --query "{address: ipAddress}"
az network public-ip list -g $rgHub -o table

# Route Server Peers & Routes

az network routeserver peering list --routeserver $arsName --resource-group $rgHub
peerName=csr-hub
az network routeserver peering list-learned-routes --name $peerName --routeserver $arsName --resource-group $rgHub
az network routeserver peering list-advertised-routes --name $peerName --routeserver $arsName --resource-group $rgHub

# hub effective routes
az network nic show-effective-route-table -g $rgHub -n $nicHubVm1 --output table
# spoke effective routes
az network nic show-effective-route-table -g $rgSpoke -n $nicSp1Vm1 --output table
# onprem effective routes
az network nic show-effective-route-table -g $rgOnprem -n $nicOnpremVm1 --output table