		-------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------------------------------------
		/*							 Triggers Adaptadas ao SmartContractMonotoring										 */
		-------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------------------------------------
		use SmartContractMonitoring
		go

		/*
			Este Trigger previne que sejam feitas inserts no WalletInteraction se a Wallet nao existir.
			Tambem evita interacoescom a SmartContract caso nao hajma mais vagas de participacao

		*/
		drop trigger trg_InsertWalletInteraction

		create trigger trg_InsertWalletInteraction
		on WalletInteractions
		instead of insert
		as
		begin
			set nocount on;

			-- Declaração de uma tabela temporária para armazenar as inserções válidas
			declare @ValidInsertions table(
					WalletAddress varchar(200),
					InteractionId int
			)

			----------------------------------------------------------------------------------
			-- 1. Identificar e inserir linhas validas na tabela temporaria
			-- Uma linha é considerada válida se:
			-- A) A Wallet e a Interaction existem (Integridade Referencial)
			-- B) O registo não existe em WalletInteractions (Evitar Duplicação)
			-- C) A Interaction ainda tem vagas disponíveis (Regra de Negócio)
			----------------------------------------------------------------------------------
			insert into @ValidInsertions (WalletAddress, InteractionId)
			select i.WalletAddress, i.InteractionId
			from inserted i
			inner join Wallets w on i.WalletAddress = w.WalletAddress
			inner join UserInteractions ui on  i.InteractionId = ui.InteractionId
			where not exists ( -- apenas serao inseridas dentro do @ValidInsertions as carteiras que nao existem na base de dados
								select 1 
								from WalletInteractions wi
								where wi.WalletAddress = i.WalletAddress
								and wi.InteractionId = i.InteractionId
					)
			and ui.MaxParticipants > ui.TotalParticipants -- garante que o nr de participantes nao ultrapasse a lotacao de interacoes possiveis com o SmartContract

			---------------------------------------------------------------------------------------
			-- 2. Tratamento de erros
			-- Este bloco identifica as linhas que falharam nas regras específicas e levanta erros.
			----------------------------------------------------------------------------------------
			-- Erro de Wallet inexistente
			if exists ( 
						select 1 
						from inserted i left join Wallets w 
						on i.WalletAddress = w.WalletAddress 
						where w.WalletAddress is null
					)
					begin
						raiserror('Uma ou mais wallet não existe na table Wallet', 16, 1)
					end
			
			-- Erro de Interação inexistente
			else if exists ( 
						select 1 
						from inserted i left join UserInteractions ui 
						on i.InteractionId = ui.InteractionId 
						where ui.InteractionId is null
					)
					begin
						raiserror('Uma ou mais interaction não existe na table UserInteractions', 16, 1)
					end

			-- Erro de Duplicaçao
			else if exists ( 
						select 1 
						from inserted i,  WalletInteractions wi 
						where wi.WalletAddress = i.WalletAddress 
						and wi.InteractionId = i.InteractionId
					)
					begin
						raiserror('Uma wallet com este registo ja existe no sistema', 16, 1)
					end

			-- Erro de Vagas Esgotadas
			else if exists ( 
						select 1 
						from inserted i,  UserInteractions ui 
						where ui.InteractionId = i.InteractionId
						and ui.MaxParticipants <= ui.TotalParticipants
						and not exists ( -- Exclui as que já falharam por outros motivos (e.g., wallet/interaction inexistente)
										select 1 
										from  @ValidInsertions vi, inserted i
										where vi.WalletAddress = i.WalletAddress 
										and vi.InteractionId = i.InteractionId
										)
					)
					begin
						raiserror('Já não há interações possiveis', 16, 1)
					end

			----------------------------------------------------------------------------------
			-- 3. Inserir os registos na tabela WalletInteractions e atualizar o numero 
			--    de participantes na UserInteractions
			-- 
			----------------------------------------------------------------------------------

			-- Inserir as linhas válidas da tabela temporária para a tabela final
			insert into WalletInteractions (WalletAddress, InteractionId, JoinedAt)
   			select WalletAddress, InteractionId, getdate()
			from @ValidInsertions;

			-- Atualizar o TotalParticipants para todas as Interactions que receberam novos registos
			with CountedValid as ( 
									select InteractionId, count(*) NewRegistrations
       								from @ValidInsertions
       								group by InteractionId
								)

   			update ui
   			set ui.TotalParticipants = ui.TotalParticipants + cv.NewRegistrations
   			from UserInteractions ui, CountedValid cv
			where ui.InteractionId = cv.InteractionId
		end



			----------------------------------------------------------------------------------
			--								Testes do Trigger					     		--
			----------------------------------------------------------------------------------	
			-- Teste 1 
			-- *** Carteiras de Teste ***
			select * from Wallets
			insert into Wallets (WalletAddress, FirstSeen)
				values -- ('0xTestWalletA','2025-01-01 00:00:00'),
				--	   ('0xTestWalletB','2025-01-01 00:00:00'),
					   ('0xTestWalletD','2025-01-01 00:00:00');

			-- *** Interação de Teste (2 vagas) ***
			select * from UserInteractions
			insert into UserInteractions (ContractAddress, InteractionTypeCode, ScheduledAt, DurationMinutes, 
							TotalParticipants, MaxParticipants, MinWalletAgeDays, InteractionState)
				values	('0xB33f45A6Dc6c47Aa0b5a5E2a5F01d4b2e9C7b434', 2, '2025-02-01 10:00:00', 60, 
						0,   -- TotalParticipants inicial: 0
						2,   -- MaxParticipants: 2 (Apenas 2 vagas)
						0, 1);

			-- Verificar o ID da nova interação
			select InteractionId, TotalParticipants, MaxParticipants from UserInteractions where MaxParticipants = 2;
				-- Assumimos que o InteractionId é 3 para os testes.


			
			-- Inserção 1: Válida, Repetir para dar um erro de duplicacao
			select * from WalletInteractions
			insert into WalletInteractions (WalletAddress, InteractionId)
			values ('0xTestWalletB', 4);
