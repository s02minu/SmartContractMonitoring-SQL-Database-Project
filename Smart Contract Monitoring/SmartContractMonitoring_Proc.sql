		-------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------------------------------------
		/*							 Procedimento Adaptadas ao SmartContractMonotoring									 */
		-------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------------------------------------

		/* Proc 
			  
			  O objetivo do usp_InsertEventType é evitar que sejam inseridos tipos de eventos 
			  duplicados na tabela EventTypes.

			  Ou seja, este procedimento garante que:
				- não existe nenhum outro EventType com o mesmo EventTypeCode
				- não existe nenhum outro EventType com o mesmo EventName (ignorando letras maiúsculas/minúsculas)
				- Se alguma destas condições falhar, ele não deixa inserir e devolve um erro informativo.
		*/

		if object_id ('usp_InsertEventType', 'p') is not null
		drop proc usp_InsertEventType
		go

		create proc usp_InsertEventType
					@code int,
					@name varchar(200)
		as
		begin
			-- Verificar se ja existe um EventType com o mesmo nome ou codigo
			if exists (
						select 1
						from EventTypes
						where EventTypeCode = @code
						or lower(EventName) = lower(@name)
				)
				begin
					raiserror('Já existe um tipo de evento com esse código ou nome!', 16, 1)
					return -- Parar aqui sem realizar o insert
				end

				-- Caso tenha oassado a validacao, fazer a insercao em seguranca
				insert into EventTypes (EventTypeCode, EventName)
					 values (@code, @name);
		end
		go

		/* Teste de insercao */
		select * from EventTypes

		exec usp_InsertEventType @code = 7, @name = 'Mint';

		select * from EventTypes