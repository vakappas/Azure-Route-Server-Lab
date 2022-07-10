az network vpn-connection create -g MyResourceGroup -n MyConnection --vnet-gateway1 MyVnetGateway --local-gateway2 MyLocalGateway --shared-key Abc123 --ingress-nat-rule /subscriptions/000/resourceGroups/TestBGPRG1/providers/Microsoft.Network/virtualNetworkGateways/gwx/natRules/nat

New-AzVirtualNetworkGatewayConnection -Name $Connection12 -ResourceGroupName $RG1 -VirtualNetworkGateway1 $vnet1gw -VirtualNetworkGateway2 $vnet2gw -Location $Location1 -ConnectionType Vnet2Vnet -SharedKey 'AzureA1b2C3' -EnableBgp $True

New-AzVirtualNetworkGatewayConnection -Name $Connection21 -ResourceGroupName $RG2 -VirtualNetworkGateway1 $vnet2gw -VirtualNetworkGateway2 $vnet1gw -Location $Location2 -ConnectionType Vnet2Vnet -SharedKey 'AzureA1b2C3' -EnableBgp $True