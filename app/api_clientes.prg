function api_clientes( oDom )


	do case
		case oDom:GetProc() == 'ayuda_cliente'            	; DoHelpCli( oDom )
		case oDom:GetProc() == 'seleccionar_cliente'        ; DoSelecionar_Cliente( oDom )
		case oDom:GetProc() == 'exe_consulta'       		; DoExeConsulta(oDom)
		case oDom:GetProc() == 'nav_refresh'				; DoNav_Refresh( oDom )
		case oDom:GetProc() == 'nav_top'					; DoNav_Top( oDom )
		case oDom:GetProc() == 'nav_prev'					; DoNav_Prev( oDom )
		case oDom:GetProc() == 'nav_next'					; DoNav_Next( oDom )
		case oDom:GetProc() == 'nav_end'					; DoNav_End( oDom )
		case oDom:GetProc() == 'nav_print'					; DoNav_Print( oDom )
			otherwise
			oDom:SetError( "Proc don't defined => " + oDom:GetProc())
	endcase


retu oDom:Send()


// -------------------------------------------------- //

static function DoHelpCli( oDom )

	local cHtml := ULoadHtml( '../html/ayudas/ayuda_cliente.html'  )
	local o     := {=>}

	o[ 'title' ] := 'Clientes'
	oDom:SetDialog( 'xxx', cHtml, nil, o )

retu nil

//----------------------------------------------------------------------------//
Function DoExeConsulta( oDom )
	local hInfo := InitInfo( oDom )

	// Abrir base de datos

	IF ! OpenConnect(oDom, hInfo)
		retu .f.
	endif

	// Obtener total de registros
	if ! TotalRows( oDom, hInfo )
		CloseConnect( oDom, hInfo )
	endif

	// Cargar datos de la primera página
	LoadRows( oDom, hInfo, .T. )  // .T. = inicializar browse

	// Cerrar conexión
	CloseConnect( oDom, hInfo )

	// Actualizar controles DOM
	Refresh_Nav( oDom, hInfo )

RETURN .t.



// -------------------------------------------------- //

static function OpenConnect( oDom, hInfo )
	// Para clientes usamos la función existente Conect_mysql()
	//hInfo[ 'db' ] := Conect_mysql(oDom, hInfo)

	Conect_database(oDom,@hInfo)

	IF hInfo[ 'lerror' ]
		oDom:SetError(hInfo['lerrordetalle'])
		retu .f.
	ENDIF

retu .t.


//	--------------------------------------------------------

static function InsRow(oQry)

	local hRow := 	{ ;
		'CODE' => oQry:codcli,;
		'FULLNAME'  => oQry:nomcli  }

return hRow
// -------------------------------------------------- //

static function DoNav_Next( oDom )

	local hInfo	:= InitInfo( oDom )

	//	Open Database

	if ! OpenConnect( oDom, hInfo )
		retu nil
	endif

	//	Refresh Total rows

	if ! TotalRows( oDom, hInfo )
		retu nil
	endif

	//	Update page

	hInfo[ 'page' ]++

	if hInfo[ 'page' ] > hInfo[ 'page_total' ]
		hInfo[ 'page' ] := hInfo[ 'page_total' ]
	endif

	//	Load data...

	LoadRows( oDom, hInfo )

	//	Close database connection

	CloseConnect( oDom, hInfo )

	//	Refresh Dom

	Refresh_Nav( oDom, hInfo )

retu nil
// -------------------------------------------------- //

static function InitInfo( oDom )

	local hInfo := {=>}

	hInfo[ 'total' ] 		:= 0
	hInfo[ 'page' ] 		:= Val( oDom:Get( 'nav_page', '1' ))
	hInfo[ 'page_rows' ] 	:= Val( oDom:Get( 'nav_page_rows', '10' ))
	hInfo[ 'page_total' ] 	:= 0

retu hInfo


// -------------------------------------------------- //

static function CloseConnect( oDom, hInfo )
	if HB_HHasKey( hInfo, 'db' ) .and. hInfo[ 'db' ] != NIL
		hInfo[ 'db' ]:End()
	endif
retu nil

// -------------------------------------------------- //

static function TotalRows( oDom, hInfo )
	local oQry, nTotal := 0

	hInfo[ 'total' ] := 0

	// Consulta para obtener el total de registros
	oQry := hInfo[ 'db' ]:Query( "SELECT COUNT(*) as total FROM munmacli" )

	IF oQry != NIL
		nTotal := oQry:total
		hInfo[ 'total' ] := nTotal
	ELSE
		oDom:SetError( 'Error counting records' )
		retu .f.
	ENDIF

	// Calcular total de páginas
	hInfo[ 'page_total' ] := Int( hInfo[ 'total' ] / hInfo[ 'page_rows' ] ) + ;
		if( hInfo[ 'total' ] % hInfo[ 'page_rows' ] == 0, 0, 1 )

	// Validar página actual
	if hInfo[ 'page' ] > hInfo[ 'page_total' ] .or. hInfo[ 'page' ] <= 0
		hInfo[ 'page' ] := 1
	endif

retu .t.

// -------------------------------------------------- //

static function LoadRows( oDom, hInfo, lInitBrw )
	local oQry, aClientes := {}, aRow := {}
	local cSql, nRowInit

	hb_default( @lInitBrw, .f. )

	// Calcular OFFSET para la paginación
	nRowInit := ( hInfo[ 'page' ] - 1 ) * hInfo[ 'page_rows']

	// Construir SQL con LIMIT y OFFSET
	cSql := "SELECT row_id, codcli, nomcli FROM munmacli LIMIT " + ;
		ltrim(str(hInfo[ 'page_rows' ])) + " OFFSET " + ltrim(str(nRowInit))

	oQry := hInfo[ 'db' ]:Query( cSql )

	IF oQry != NIL
		oQry:gotop()
		DO WHILE ! oQry:Eof()
			aRow := { 'ROW_ID' => oQry:row_id, 'CODCLI' => oQry:codcli, 'NOMCLI' => hb_strtoutf8(oQry:nomcli) }
			AADD( aClientes, aRow )
			oQry:Skip()
		END
	ELSE
		oDom:SetError( 'Error loading data' )
		retu .f.
	ENDIF

	// Actualizar tabla
	oDom:TableSetData( 'clientes', aClientes )

retu .t.

// -------------------------------------------------- //

static function Refresh_Nav( oDom, hInfo )
	oDom:Set( 'nav_total'		, hInfo[ 'total' ] )
	oDom:Set( 'nav_page'		, ltrim(str(hInfo[ 'page' ])) )
	oDom:Set( 'nav_page_rows'	, ltrim(str(hInfo[ 'page_rows' ])) )
	oDom:Set( 'nav_page_total'	, ltrim(str(hInfo[ 'page_total' ])) )
retu nil

// -------------------------------------------------- //

static function DoNav_Top( oDom )
	local hInfo	:= InitInfo( oDom )

	// Abrir base de datos
	if ! OpenConnect( oDom, hInfo )
		retu nil
	endif

	// Obtener total de registros
	if ! TotalRows( oDom, hInfo )
		retu nil
	endif

	// Ir a primera página
	hInfo[ 'page' ] := 1

	// Cargar datos
	LoadRows( oDom, hInfo )

	// Cerrar conexión
	CloseConnect( oDom, hInfo )

	// Actualizar controles DOM
	Refresh_Nav( oDom, hInfo )

retu nil

// -------------------------------------------------- //

static function DoNav_End( oDom )
	local hInfo	:= InitInfo( oDom )

	// Abrir base de datos
	if ! OpenConnect( oDom, hInfo )
		retu nil
	endif

	// Obtener total de registros
	if ! TotalRows( oDom, hInfo )
		retu nil
	endif

	// Ir a última página
	hInfo[ 'page' ] := hInfo[ 'page_total' ]

	// Cargar datos
	LoadRows( oDom, hInfo )

	// Cerrar conexión
	CloseConnect( oDom, hInfo )

	// Actualizar controles DOM
	Refresh_Nav( oDom, hInfo )

retu nil

// -------------------------------------------------- //

static function DoNav_Prev( oDom )
	local hInfo	:= InitInfo( oDom )

	// Abrir base de datos
	if ! OpenConnect( oDom, hInfo )
		retu nil
	endif

	// Obtener total de registros
	if ! TotalRows( oDom, hInfo )
		retu nil
	endif

	// Ir a página anterior
	hInfo[ 'page' ]--

	if hInfo[ 'page' ] <= 0
		hInfo[ 'page' ] := 1
	endif

	// Cargar datos
	LoadRows( oDom, hInfo )

	// Cerrar conexión
	CloseConnect( oDom, hInfo )

	// Actualizar controles DOM
	Refresh_Nav( oDom, hInfo )

retu nil

// -------------------------------------------------- //

static function DoNav_Refresh( oDom, hInfo )

	// Inicializar información si no se proporciona
	if hInfo == NIL
		hInfo := InitInfo( oDom )
	endif

	// Abrir base de datos
	if ! OpenConnect( oDom, hInfo )
		retu nil
	endif

	// Obtener total de registros
	if ! TotalRows( oDom, hInfo )
		retu nil
	endif

	// Cargar datos
	LoadRows( oDom, hInfo )

	// Actualizar controles DOM
	Refresh_Nav( oDom, hInfo )

	// Cerrar conexión
	CloseConnect( oDom, hInfo )

retu nil
// -------------------------------------------------- //

static function DoNav_Print( oDom )
	oDom:TablePrint( 'clientes' )
retu nil
// -------------------------------------------------- //

static function DoSelecionar_Cliente (oDom)

	local hBrowse := oDom:Get( 'clientes' )
	local aSelected := hBrowse[ 'selected' ]
	local nRowId, hInfo, oQry, hFull, cInfoCliente := ""
	
	if len(aSelected) > 0
		nRowId := aSelected[1]['ROW_ID']
		
		hInfo := InitInfo( oDom )
		if ! OpenConnect( oDom, hInfo )
			retu nil
		endif
		
		oQry := hInfo['db']:Query( "SELECT * FROM munmacli WHERE row_id = " + ltrim(str(nRowId)) + " LIMIT 1" )
		
		if oQry != NIL .and. !oQry:eof()
			hFull := oQry:FillHRow()
			
			//oDom:Console({ 'cliente' => hFull })
		
			cInfoCliente := "ID: " + ltrim(str(hFull['row_id'])) + CHR(13) + CHR(10) + ;
				"Código: " + hFull['codcli'] + CHR(13) + CHR(10) + ;
				"Nombre: " + hb_strtoutf8(hFull['nomcli']) + CHR(13) + CHR(10) ;
													
			oDom:SetDlg( 'form_pedidos' )
			oDom:Set( 'mymemo1', cInfoCliente )
			
			oDom:DialogClose('ayuda_cliente')
		endif
		
		CloseConnect( oDom, hInfo )
	endif
retu nil