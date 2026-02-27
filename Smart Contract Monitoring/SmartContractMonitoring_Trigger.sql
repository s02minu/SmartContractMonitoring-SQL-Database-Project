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
	--drop trigger trg_InsertWalletInteraction
	
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
	
		-- *** Preparar o terreno para novo teste  ***
	
		delete from WalletInteractions where WalletAddress like '0xTestWallet%';
		delete from Wallets where WalletAddress like '0xTestWallet%';
		delete from UserInteractions where ContractAddress = '0xTESTCONTRACT';
		delete from SmartContracts where ContractAddress = '0xTESTCONTRACT';
	
		
		-- *** Criar Carteiras de Teste ***
		insert into Wallets (WalletAddress, FirstSeen)
			values  ('0xTestWalletA','2025-01-01 00:00:00'),
				   ('0xTestWalletB','2025-01-01 00:00:00'),
				   ('0xTestWalletC','2025-01-01 00:00:00');
	
		select * 
		from Wallets 
		where WalletAddress like '0xTestWallet%'; -- Verificar se for criado
	
	
		-- *** Criar ContractoInteligente Teste ***
		insert into SmartContracts (ContractAddress, ContractName, Symbol, DeployedAt, TotalInteractions, RiskLevelCode) 
		values	('0xTESTCONTRACT','Teste','TST','2025-12-01 10:00:00',5,2)
	
		select * 
		from SmartContracts 
		where ContractAddress = '0xTESTCONTRACT'; -- Verificar se for criado
	
	
		-- *** Criar Interação dos Utilizadores (2 vagas) ***
		insert into UserInteractions 
					(ContractAddress, InteractionTypeCode, ScheduledAt, DurationMinutes, TotalParticipants, MaxParticipants, MinWalletAgeDays, InteractionState)
			values	('0xTESTCONTRACT', 1, '2025-02-01 10:00:00', 60, 0, 2 /* Apenas 2 vagas */, 0, 1);
	
	
		select * 
		from UserInteractions 
		where ContractAddress = '0xTESTCONTRACT' -- Verificar se for criado 
	
	
		
	
		-- *** Teste 1 - inserção válida ***
		declare @TestInteractionId int;
		set @TestInteractionId = (select InteractionId from UserInteractions where ContractAddress = '0xTESTCONTRACT')
	
		insert into WalletInteractions (WalletAddress, InteractionId)
		values ('0xTestWalletA', @TestInteractionId);
	
		select * 
		from WalletInteractions 
		where InteractionId = @TestInteractionId;
	
		select InteractionId, TotalParticipants
		from UserInteractions 
		where InteractionId = @TestInteractionId;
		go
	
	
		-- *** Teste 2 - inserção válida (Prencher todas as vagas) ***
		declare @Test2InteractionId int;
		set @Test2InteractionId = (select InteractionId from UserInteractions where ContractAddress = '0xTESTCONTRACT')
	
		insert into WalletInteractions (WalletAddress, InteractionId)
		values ('0xTestWalletB', @Test2InteractionId);
	
		select * 
		from WalletInteractions 
		where InteractionId = @Test2InteractionId;
	
		select InteractionId, TotalParticipants
		from UserInteractions 
		where InteractionId = @Test2InteractionId;
		go
	
	
		-- *** Teste 3 - inserção inválida (vagas já todas ja preenchidas) ***
		declare @Test3InteractionId int;
		set @Test3InteractionId = (select InteractionId from UserInteractions where ContractAddress = '0xTESTCONTRACT')
	
		insert into WalletInteractions (WalletAddress, InteractionId)
		values ('0xTestWalletC', @Test3InteractionId);
	
		select * 
		from WalletInteractions 
		where InteractionId = @Test3InteractionId;
	
		select InteractionId, TotalParticipants
		from UserInteractions 
		where InteractionId = @Test3InteractionId;
		go
	
		-- *** Teste 4 - inserção duplicda (deve falhar) ***
		declare @Test4InteractionId int;
		set @Test4InteractionId = (select InteractionId from UserInteractions where ContractAddress = '0xTESTCONTRACT')
	
		insert into WalletInteractions (WalletAddress, InteractionId)
		values ('0xTestWalletA', @Test4InteractionId);
	
		select * 
		from WalletInteractions 
		where InteractionId = @Test4InteractionId;
	
		select InteractionId, TotalParticipants
		from UserInteractions 
		where InteractionId = @Test4InteractionId;
		go
	
		-- *** Teste 5 - inserção invalida, carteira inexistente (deve falhar) ***
		declare @Test5InteractionId int;
		set @Test5InteractionId = (select InteractionId from UserInteractions where ContractAddress = '0xTESTCONTRACT')
	
		insert into WalletInteractions (WalletAddress, InteractionId)
		values ('0xFakeWalletZZZ', @Test5InteractionId);
	
		select * 
		from WalletInteractions 
		where InteractionId = @Test5InteractionId;
	
		select InteractionId, TotalParticipants
		from UserInteractions 
		where InteractionId = @Test5InteractionId;
		go
	
		-- *** Teste 6 - inserção de id inexistente (deve falhar) ***
		declare @Test6InteractionId int;
		set @Test6InteractionId = 999
	
		insert into WalletInteractions (WalletAddress, InteractionId)
		values ('0xTestWalletA', @Test6InteractionId);
	
		select * 
		from WalletInteractions 
		where InteractionId = @Test6InteractionId;
	
		select InteractionId, TotalParticipants
		from UserInteractions 
		where InteractionId = @Test6InteractionId;
		go



		-- delete  from Wallets where WalletAddress = '0xTestWalletD'
