function api_recepcion( oDom )

do case
		case oDom:GetProc() == 'helpCli'		; DoHelpCli( oDom )
		otherwise 				
			oDom:SetError( "Proc don't defined => " + oDom:GetProc())
	endcase
	
retu oDom:Send()

// -------------------------------------------------- //

static function DoHelpCli( oDom )

	// local cprueba := 'Info del cliente' + CHR(13) + CHR(10) + 'direccion'
	// oDom:Set( 'mymemo1', cprueba )

	local cHtml := ULoadHtml( '../html/ayudas/ayuda_cliente.html'  )
	local o 	:= {=>}	

		
	o[ 'title' ] 		:= 'Clientes'
		
		

	oDom:SetDialog( 'xxx', cHtml, nil, o )

retu nil