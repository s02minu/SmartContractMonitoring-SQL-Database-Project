		
		/***** 
			Este script foi criado para substituir a base de dados e os exercícios da Tarefa "Caminhadas Pedestres".

			Com o objetivo de criar uma plataforma que simula o que acontece num ambiente blockchain, pedi ao ChatGPT 
			que gerasse tabelas capazes de auditar e acompanhar as interações entre os vários elementos que constituem 
			o universo blockchain. Neste caso em particular, o Ethereum.

			Antes da criação das tabelas, tentei fazer o fetch dos dados através de uma API, mas obtive o erro 401 — 
			ou seja, não tinha autorização para aceder à API. Como estava limitado de tempo, decidi simplesmente criar 
			tabelas fictícias com o apoio de uma ferramenta de IA.

			É importante salientar que algumas tabelas não funcionam exatamente como funcionariam num ecossistema 
			blockchain real, mas para seguir a lógica exigida na tarefa do formador, tiveram de ser criadas dessa forma.
		*****/


		-------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------------------------------------
		/*												create database 												 */
		-------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------------------------------------
		go
		use master

		if db_id ('SmartContractMonitoring') is not null
		drop database SmartContractMonitoring

		create database SmartContractMonitoring
		go

		-------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------------------------------------
		/*												drop tables se existirem						    			 */
		-------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------------------------------------
		use SmartContractMonitoring

		if object_id ('SmartContracts', 'u') is not null
		drop table SmartContracts 

		go

		-------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------------------------------------
		/*								create das tables numa ordem que evita erros									 */
		-------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------------------------------------
		/* Tabela TransactionStatus


		   Função:
			  Tabela de referência que define e padroniza os estados possíveis de execução das 
			  transações no Ethereum. Cada entrada representa o resultado final de uma transação 
			  no blockchain.

		   Exemplos de estados comuns:
			  - Success
			  - Failed
			  - Reverted
			  - Out of Gas

		   Porque existe:
			  Garante consistência nos registos, evitando erros ortográficos, padronizando os 
			  estados das transações e permitindo futuras expansões ou análises.

		   Equivalência com Ethereum:
			  Corresponde ao campo 'status' no "transaction receipt" e permite mapear de forma 
			  clara o resultado de cada transação na blockchain.

		*/

		create table TransactionStatus (
			StatusCode int primary key,
			StatusName varchar(50) 
		)

		-------------------------------------------------------------------------------------------------------------------

		/* Tabela EventTypes

		   Função:
			  Lista e padroniza todos os tipos de eventos que podem ser emitidos por um contrato inteligente. 
			  Estes eventos representam logs gravados na blockchain sempre que ocorre uma alteração relevante
			  no estado do contrato.

		   Exemplos de eventos comuns:
			  - Transfer
			  - Approval
			  - Mint
			  - Burn
			  - Swap

		   Porque existe:
			  Os eventos são fundamentais para auditoria e monitorização de contratos inteligentes. 
			  Armazená-los de forma estruturada evita inconsistências, assegura integridade referencial 
			  e facilita análises posteriores.

		   Relação com o blockchain:
			  Esta tabela corresponde aos nomes dos eventos definidos no ABI (Application Binary Interface) 
			  dos contratos inteligentes. Cada entrada aqui mapeia um tipo específico de log gerado durante 
			  a execução das transações.
		*/

		create table EventTypes (
			EventTypeCode int primary key,
			EventName varchar(100) 
		)

		-------------------------------------------------------------------------------------------------------------------

		/* Tabela InteractionTypes

		   Função:
			  Define e padroniza todas as categorias de interações que um utilizador pode iniciar 
			  com um contrato inteligente. Enquanto EventTypes representam eventos emitidos pelo 
			  contrato, InteractionTypes representam ações iniciadas pelo utilizador, que podem 
			  gerar esses eventos ou alterar o estado do contrato.

		   Exemplos de interações comuns:
			  - Depósito
			  - Levantamento
			  - Swap
			  - Participação
			  - Stake
			  - Reclamar Recompensas

		   Porque existe:
			  Categorizar as interações dos utilizadores permite organizar e abstrair as ações 
			  realizadas, evitando inconsistências de nomenclatura, facilitando auditoria e 
			  análises de comportamento, e garantindo integridade dos registos.

		   Relação com o blockchain:
			  Cada tipo de interação aqui corresponde a uma ação concreta realizada na blockchain, 
			  geralmente ligada a eventos registrados pelo contrato inteligente. Esta tabela fornece 
			  um mapeamento claro entre as ações dos utilizadores e os logs/eventos que são gerados.
		*/

		
		create table InteractionTypes  (
			InteractionTypeId int primary key,
			InteractionName varchar(100) -- e.g. Transfer, Approval, Execution
		)

		-------------------------------------------------------------------------------------------------------------------
		
		/* Tabela Auditors

		   Função:
			  Representa auditores ou especialistas responsáveis pela validação, supervisão e análise 
			  das interações com contratos inteligentes. Estes profissionais registam observações e 
			  asseguram que as operações seguem boas práticas e padrões de segurança.

		   Exemplos de atributos:
			  - AuditorId
			  - AuditorName
			  - Company
			  - HourlyRate

		   Porque existe:
			  No mundo real, qualquer plataforma de auditoria ou sistema financeiro inclui profissionais 
			  que analisam processos, validam transações críticas e monitorizam atividades. Esta tabela 
			  permite modelar essa função de forma estruturada e auditar interações relevantes.

		   Equivalência com blockchain:
			  Apesar de ser uma entidade off-chain, os auditores desempenham um papel crucial na 
			  supervisão e confiança do ecossistema, especialmente em processos que não podem ser 
			  totalmente automatizados no smart contract.
		*/

		create table Auditors (
			AuditorId int identity(1,1) primary key,
			AuditorName varchar(200),
			Company varchar(200),
			HourlyRate decimal(10,2) -- price/hour for audit work
		)

		-------------------------------------------------------------------------------------------------------------------

		/* Tabela Admins

		   Função:
			  Representa os administradores da plataforma, responsáveis por gerir o sistema, 
			  configurar contratos inteligentes e manter a operação segura e eficiente.

		   Exemplos de atributos:
			  - AdminId
			  - Username
			  - Email
			  - IsSuperAdmin

		   Porque existe:
			  Tal como em qualquer dashboard ou plataforma, os administradores são essenciais 
			  para controlar acessos, gerir utilizadores, auditores e dados, e garantir que 
			  todas as operações seguem as políticas definidas.

		   Equivalência com blockchain:
			  Embora os administradores sejam entidades off-chain, desempenham papel crítico 
			  no controlo, supervisão e manutenção da integridade da plataforma que interage 
			  com contratos inteligentes.
		*/

		create table Admins (
			AdminId int identity(1,1) primary key,
			Username varchar(100),
			Email varchar(200),
			IsSuperAdmin bit default 0
		)

		-------------------------------------------------------------------------------------------------------------------
		/* Tabela Wallets

		   Função:
			  Armazena todas as carteiras (endereços) que participam no ecossistema blockchain, 
			  permitindo acompanhar e analisar a atividade de cada utilizador ou entidade.

		   Campos importantes:
			  - WalletAddress : endereço único da carteira
			  - FirstSeen : primeira vez que a carteira foi observada no sistema
			  - TotalSent / TotalReceived : métricas agregadas de transações enviadas e recebidas
			  - TotalInteractions : volume total de ações/interações realizadas pela carteira

		   Porque existe:
			  É fundamental ter uma tabela normalizada de carteiras para:
				 - relacionar com transações
				 - relacionar com eventos
				 - relacionar com interações de utilizadores
			  Isso assegura consistência, integridade referencial e facilita análises de comportamento e auditoria.

		   Equivalência com blockchain:
			  Cada entrada representa um endereço ativo na blockchain, permitindo mapear todas 
			  as transações e interações associadas a essa carteira.
		*/

		create table Wallets (
			WalletAddress varchar(200) primary key,
			FirstSeen datetime,
			TotalSent decimal(38,18) default 0,
			TotalReceived decimal(38,18) default 0,
			TotalInteractions int default 0
		)

		-------------------------------------------------------------------------------------------------------------------

		/* Tabela RiskLevel

		   Função:
			  Define e padroniza os níveis de risco atribuídos a contratos inteligentes, permitindo 
			  identificar rapidamente a segurança ou complexidade de um contrato.

		   Exemplos de níveis de risco:
			  - Baixo risco (auditado)
			  - Médio risco
			  - Alto risco (proxy complexo)
			  - Risco crítico (padrões de scam)

		   Porque existe:
			  A avaliação de risco é essencial em auditorias de blockchain. Esta tabela permite 
			  classificar contratos, aplicar filtros de análise e priorizar revisões de segurança.

		   Equivalência com blockchain:
			  Cada nível de risco fornece uma referência off-chain sobre a confiabilidade ou 
			  vulnerabilidade potencial de um contrato inteligente, ajudando na tomada de decisão 
			  por utilizadores e auditores.
		*/

		create table RiskLevel (
			RiskLevelCode int primary key,
			RiskDescription varchar(200)
		)

		-------------------------------------------------------------------------------------------------------------------

		/* Tabela SmartContracts

		   Função:
			  Representa cada contrato inteligente monitorizado na plataforma, funcionando 
			  como a tabela central da base de dados. Permite acompanhar interações, atributos 
			  do contrato e seu nível de risco.

		   Porque existe:
			  Todas as restantes tabelas (Transactions, EventTypes, InteractionTypes, etc.) 
			  ligam direta ou indiretamente a esta tabela. Ela serve como referência central 
			  para análise e auditoria de contratos.

		   Equivalência com blockchain:
			  Cada registo corresponde a um contrato real implantado na Ethereum, permitindo 
			  mapear transações, eventos e interações associadas de forma estruturada.
		*/

		create table SmartContracts (
			ContractAddress  varchar(200) primary key,
			ContractName  varchar(200),
			Symbol  varchar(50),
			DeployedAt datetime,
			TotalInteractions int,
			RiskLevelCode int not null,

			foreign key (RiskLevelCode) references RiskLevel (RiskLevelCode)
		)

		-------------------------------------------------------------------------------------------------------------------

		/* Tabela ContractEvents

		   Função:
			  Armazena cada evento emitido por contratos inteligentes, permitindo auditar e 
			  analisar alterações de estado geradas durante a execução de transações.

		   Exemplos de eventos comuns:
			  - Transfer
			  - Mint
			  - Burn
			  - Log de Swap


		   Porque existe:
			  Os eventos são essenciais para compreender a atividade de um contrato inteligente. 
			  Armazená-los de forma estruturada permite rastrear alterações de estado, auditar 
			  transações e analisar padrões de comportamento.

		   Equivalência com blockchain:
			  Cada registo corresponde a um evento real emitido por um contrato na blockchain, 
			  tal como definido no ABI do contrato.
		*/

		create table ContractEvents (
			EventId int identity(1,1) primary key,
			ContractAddress varchar(200),
			EventTypeCode int,
			BlockNumber bigint,
			BlockTimeStamp datetime,
			TxHash varchar(200),
			fromAddress varchar(200),
			ToAddress varchar(200),
			Amount decimal(38,18),
			Details nvarchar(max),

			foreign key (ContractAddress) references SmartContracts (ContractAddress),	
			foreign key (EventTypeCode) references EventTypes (EventTypeCode)
			)

		-------------------------------------------------------------------------------------------------------------------

		/* Tabela ContractEventLinks

		   Função:
			  Liga contratos inteligentes a eventos, permitindo mapear situações em que:
				 - um evento envolve múltiplos contratos 
				 - é necessário associar eventos específicos a contratos específicos

		   Porque existe:
			  Esta tabela funciona como uma tabela de junção (many-to-many), garantindo 
			  maior flexibilidade na modelagem dos dados e permitindo análises precisas 
			  sobre eventos relacionados a múltiplos contratos.

		   Equivalência com blockchain:
			  Cada ligação representa uma associação off-chain que mapeia eventos emitidos por 
			  contratos inteligentes, refletindo interações complexas entre múltiplos contratos.
		*/

		create table ContractEventLinks (
			Id int identity(1,1) primary key,
			ContractAddress varchar(200),
			EventId int,

			foreign key (ContractAddress) references SmartContracts (ContractAddress),
			foreign key (EventId) references ContractEvents (EventId)
			)

		-------------------------------------------------------------------------------------------------------------------

		/* Tabela ContractTransactions

		   Função:
			  Armazena todas as transações brutas (raw) realizadas com contratos inteligentes, 
			  permitindo auditoria e análise detalhada do comportamento das transações.

		   Porque existe:
			  Permite análises detalhadas, como:
				 - identificar bots ou comportamentos automatizados
				 - analisar padrões de interação
				 - calcular gastos de gas
				 - monitorizar volume e atividade dos contratos

		   Equivalência com blockchain:
			  Cada registo corresponde a uma transação real na Ethereum, permitindo mapear 
			  de forma estruturada todas as interações entre utilizadores e contratos inteligentes.
		*/

		create table ContractTransactions (
			TxHash varchar(200) primary key,
			BlockTimeStamp datetime,
			fromAddress varchar(200),
			ToAddress varchar(200),
			Amount decimal(38,18),
			GasPrice bigint,
			GasUsed bigint,
			StatusCode int,
			InputData nvarchar(max),
			ContractAddress varchar(200),
			

			foreign key (ContractAddress) references SmartContracts (ContractAddress),
			foreign key (StatusCode) references TransactionStatus (StatusCode)
			)

			-------------------------------------------------------------------------------------------------------------------

			/* Tabela UserInteractions

			   Função:
				  Representa atividades ou interações organizadas relacionadas com contratos inteligentes, 
				  equivalentes às “caminhadas” do projeto original. Permite agrupar utilizadores e monitorizar 
				  ações específicas associadas a um contrato.

			   Exemplos de interações reais:
				  - Sessão de auditoria (audit session)
				  - Evento de staking
				  - Distribuição de tokens (airdrop)
				  - Teste coletivo em testnet
				  - Sessão educativa sobre o contrato

			   Porque existe:
				  Agrupa utilizadores em atividades específicas e permite auditoria detalhada, 
				  análise de participação e rastreio de padrões de comportamento.

			   Equivalência com blockchain:
				  Cada registo modela uma interação off-chain organizada com impacto sobre contratos 
				  inteligentes, refletindo atividades que podem gerar eventos ou transações no blockchain.
			*/

		create table UserInteractions (
			InteractionId int identity(1,1) primary key,
			ContractAddress varchar(200),
			InteractionTypeCode int,
			ScheduledAt datetime,
			DurationMinutes int,
			TotalParticipants int,
			MaxParticipants int,
			MinWalletAgeDays int,
			InteractionState bit, -- 1 = completed/active, 0 = cancelled
			
			foreign key (ContractAddress) references SmartContracts(ContractAddress),
			foreign key  (InteractionTypeCode)  references InteractionTypes(InteractionTypeId)
	
		)

		-------------------------------------------------------------------------------------------------------------------

		/* Tabela WalletInteractions

		   Função:
			  associa carteiras (Wallets) a atividades ou interações específicas (UserInteractions), 
			  permitindo rastrear a participação de cada utilizador em diferentes eventos.

		   Porque existe:
			  Permite controlar de forma estruturada:
				 - quem participou em cada interação
				 - quando cada carteira participou
				 - quantas interações cada carteira realizou
			  Funciona de forma equivalente à tabela “Inscritas” do projeto Caminhadas.

		   Equivalência com blockchain:
			  Cada registo representa a participação de uma carteira em uma interação off-chain 
			  que pode gerar eventos ou transações em contratos inteligentes.
		*/

		create table WalletInteractions (
			Id int identity(1,1) primary key,
			WalletAddress varchar(200),
			InteractionId int,
			JoinedAt datetime,

			foreign key (WalletAddress) references Wallets(WalletAddress),
			foreign key (InteractionId) references UserInteractions(InteractionId)
		)

		-------------------------------------------------------------------------------------------------------------------

		/* Tabela InteractionContract

		   Função:
			  Define quais tipos de interação (InteractionTypes) são suportados por cada contrato inteligente, 
			  permitindo mapear as capacidades específicas de cada contrato.

		   Mapeamento realista:
			  - ERC20 → Transfer, Approval
			  - DEX → Swap, AddLiquidity
			  - NFT → Mint, Transfer, Burn

		   Porque existe:
			  Nem todos os contratos suportam os mesmos tipos de interação. Esta tabela modela 
			  de forma estruturada as capacidades do contrato, tal como definido no ABI, 
			  permitindo análises e validações precisas.

		   Equivalência com blockchain:
			  Cada registo representa uma associação off-chain entre um contrato e os tipos 
			  de interações que ele permite, refletindo funcionalidade real da blockchain.
		*/

		create table InteractionContract (
			Id int identity(1,1) primary key,
			InteractionTypeCode int,
			ContractAddress varchar(200),

			foreign key (InteractionTypeCode) references InteractionTypes(InteractionTypeId),
			foreign key (ContractAddress) references SmartContracts(ContractAddress)
		)

		/* 
			Depois de verificar que os auditores estavam a auditar as interacoes dos utilizadores 
			em que de estar a audutar os SmartContract, foi necessario criar uma tablea nova e tirar o relacionamento criado
			previamente na tabela UserInteractions
		*/

		create table ContractAuditors (
			Id int identity(1,1) primary key,
			ContractAddress varchar(200),
			AuditorId int,
			AssignedAt datetime default getdate(),
			DurationMinutes int,

			foreign key (ContractAddress) references SmartContracts(ContractAddress),
			foreign key (AuditorId) references Auditors(AuditorId)
		)

	


		-------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------------------------------------
		/*											Insert nas tabelas													 */
		-------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------------------------------------
		
		-- TransactionStatus
		insert into TransactionStatus (StatusCode, StatusName)
		values (0,'Failed'),
			   (1,'Success'),
			   (2,'Reverted');

		-- RiskLevel
		insert into RiskLevel (RiskLevelCode, RiskDescription) 
		values (1,'Low'),
			   (2,'Medium'),
		       (3,'High');


		-- EventTypes
		insert into EventTypes (EventTypeCode, EventName) 
		values (1,'Transfer'),
			   (2,'Approval'),
			   (3,'ContractCreation'),
			   (4,'Execution'),
			   (5,'Other');

		-- InteractionTypes
		insert into InteractionTypes (InteractionTypeId, InteractionName) 
		values	(1,'Read'),
				(2,'Write'),
				(3,'Transfer'),
				(4,'Approve');

		-- Auditors
		insert into Auditors (AuditorName, Company, HourlyRate) 
		values  ('Alice Moreira', 'BlockSec', 180.00),
				('Ricardo Fernandes', 'SlowMist', 150.00),
				('Helena Duarte', 'Trail of Bits', 220.00),
				('Tomás Alcântara', 'OpenZeppelin', 200.00),
				('Nuno Carvalho', 'CertiK', 175.00),
				('Beatriz Sousa', 'HashEx', 130.00),
				('Carlos Martins', 'Quantstamp', 160.00),
				('Inês Figueiredo', 'PeckShield', 140.00),
				('Miguel Sampaio', 'Code4rena', 90.00),
				('Joana Ribeiro', 'Hacken', 155.00);


		-- Admins
		insert into Admins (Username, Email, IsSuperAdmin) 
		values	('admin1','israel@example.com',1),
				('instructor','rui.pereira@ipvc.pt',0);

		-- SmartContracts (3  - multi-contract system)
		insert into SmartContracts (ContractAddress, ContractName, Symbol, DeployedAt, TotalInteractions, RiskLevelCode) 
		values	('0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B','VaultX','VTX','2024-12-01 10:00:00',10,2),
				('0xB33f45A6Dc6c47Aa0b5a5E2a5F01d4b2e9C7b434','TokenBeta','TBET','2024-11-20 09:15:00',50,1),
				('0xC12e9A9F8b7C9E2d4a1F37bB8d3a0F6d2D5f8c2a','ExchangeZ','EXZ','2024-12-10 16:42:00',2,3);

	

		-- Wallets (a set of wallets that appear in the generated txs)
		insert into Wallets (WalletAddress, FirstSeen) 
		values	('0x7AcB5A3fF0A9e21E65c5D98617B8b8F3D30dA11c','2024-12-30 08:12:00'),
				('0x1F4A88F5C48eBe76A3909E77efE33B4134d0B0E3','2024-12-31 11:05:00'),
				('0xbF381a6F0b6B118CEd5d8438DFe558bAFe386c41','2025-01-01 09:22:00'),
				('0x32D3c7bc676DBda3321A966C73c0008ef8cD31A0','2024-12-29 07:45:00'),
				('0xa992114F8D43dD1a0B087E32B7F25A1af279b109','2024-12-28 18:10:00'),
				('0xb12023ccadabe99e6ba0db7cbb99f14c39db4f17','2024-12-28 19:00:00'),
				('0xc30969cd901c1a47afabc8d3d8b1c3bddfbd4b96','2024-12-28 19:30:00');

		-- UserInteractions (equivalent to Caminhadas) - examples mapped to contracts
		insert into UserInteractions (ContractAddress, InteractionTypeCode, ScheduledAt, DurationMinutes, 
					TotalParticipants, MaxParticipants, MinWalletAgeDays, InteractionState)
		values	('0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B',3,'2025-01-03 12:00:00',90,25,30,7,1),
				('0xB33f45A6Dc6c47Aa0b5a5E2a5F01d4b2e9C7b434',2,'2025-01-04 09:00:00',60,10,15,0,1);
				

		-- InteractionContract links
		insert into InteractionContract (InteractionTypeCode, ContractAddress) 
		values	(3,'0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B'),
				(2,'0xB33f45A6Dc6c47Aa0b5a5E2a5F01d4b2e9C7b434'),
				(4,'0xC12e9A9F8b7C9E2d4a1F37bB8d3a0F6d2D5f8c2a');

		-- WalletInteractions (some example signups)
		insert into WalletInteractions (WalletAddress, InteractionId, JoinedAt) 
		values	('0x7AcB5A3fF0A9e21E65c5D98617B8b8F3D30dA11c',1,'2025-01-03 11:45:00'),
				('0x1F4A88F5C48eBe76A3909E77efE33B4134d0B0E3',1,'2025-01-03 11:50:00'),
				('0xbF381a6F0b6B118CEd5d8438DFe558bAFe386c41',2,'2025-01-04 08:55:00');


		insert into ContractTransactions (TxHash, BlockTimeStamp, fromAddress, ToAddress, Amount, GasPrice, 
					GasUsed, StatusCode, InputData, ContractAddress) -- Contract A (VaultX)
		values	('0x58e1c3b4f7a28c7e743ccfe89d8d9b393a7fcbf49b13f52399b43813fe55a1e1','2025-01-02 14:22:11','0x7AcB5A3fF0A9e21E65c5D98617B8b8F3D30dA11c','0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B',0.035,21000000000,68214,1,'0xa9059cbb...00000064','0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B'),
				('0xa94a1fd8d8c49bde7df5d1864f4b75acbd3eb2d9773d29d85a8dcde299f4c8d3','2025-01-02 15:01:49','0x1F4A88F5C48eBe76A3909E77efE33B4134d0B0E3','0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B',0.12,25500000000,51290,1,'0x095ea7b3...0001','0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B'),
				('0x87e23dc31a81155dde40972fb0a201cfed56cdabecadf05ab89df9a5c429d448','2025-01-02 17:54:03','0xbF381a6F0b6B118CEd5d8438DFe558bAFe386c41','0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B',0.004,19000000000,54411,1,'0xa9059cbb...003c','0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B'),
				('0xc389257de7bde0b0b4372841cfb59f9c65e43bb1e5e2194e1738fbbec8b35c10','2025-01-03 08:22:55','0x32D3c7bc676DBda3321A966C73c0008ef8cD31A0','0xB33f45A6Dc6c47Aa0b5a5E2a5F01d4b2e9C7b434',1.25,30000000000,74421,1,'0x60806040','0xB33f45A6Dc6c47Aa0b5a5E2a5F01d4b2e9C7b434'),
				('0x2ff5b7bc0c5a62787f76f8916c95394da8771bf8d127b9b95e4210f2f06b1c35','2025-01-03 12:11:43','0xa992114F8D43dD1a0B087E32B7F25A1af279b109','0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B',0.002,15500000000,45218,1,'0xa9059cbb...0014','0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B'),
				('0x904e7f9a0ec7b89b46114436f8ffbaa8ce66f8098c05d1c5755b2c3f9ce5fc70','2025-01-03 13:47:02','0x7AcB5A3fF0A9e21E65c5D98617B8b8F3D30dA11c','0xB33f45A6Dc6c47Aa0b5a5E2a5F01d4b2e9C7b434',0.0,21000000000,60122,0,'0x095ea7b3...ffff','0xB33f45A6Dc6c47Aa0b5a5E2a5F01d4b2e9C7b434'),
				('0xa300d4de8cf54ed11527ad23dc6f0098b9b82b7bb48e5d3b221cf702c6505d32','2025-01-03 17:35:21','0xbF381a6F0b6B118CEd5d8438DFe558bAFe386c41','0xC12e9A9F8b7C9E2d4a1F37bB8d3a0F6d2D5f8c2a',0.06,22000000000,68219,1,'0xa9059cbb...0028','0xC12e9A9F8b7C9E2d4a1F37bB8d3a0F6d2D5f8c2a'),
				('0xf0e1b25324232c312f0b274af6b74de7eb635b191f4c44e4146288aa5c5eaf77','2025-01-04 10:11:33','0x32D3c7bc676DBda3321A966C73c0008ef8cD31A0','0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B',0.5,31000000000,72011,1,'0x60806040','0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B'),
				('0x1c2591e4f5f053322e2ff4d92e8397d9bce124ab86ffb63ad1c8620c754c8dc8','2025-01-04 12:43:19','0x1F4A88F5C48eBe76A3909E77efE33B4134d0B0E3','0xB33f45A6Dc6c47Aa0b5a5E2a5F01d4b2e9C7b434',0.01,20000000000,55412,1,'0xa9059cbb...000a','0xB33f45A6Dc6c47Aa0b5a5E2a5F01d4b2e9C7b434'),
				('0xfed11bc4eeec2c163b52f86af1af677cb3f63550e1dc8a9d8180450e9ad0aad4','2025-01-04 17:12:37','0xbF381a6F0b6B118CEd5d8438DFe558bAFe386c41','0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B',2.0,35000000000,91231,1,'0x095ea7b3...','0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B'),
				('0x93cb1f477e11f0a9c32eb6df1c5f7491175d37548cb8114c39fdb971aa028ae1','2025-01-05 09:11:09','0xa992114F8D43dD1a0B087E32B7F25A1af279b109','0xC12e9A9F8b7C9E2d4a1F37bB8d3a0F6d2D5f8c2a',0.0001,11000000000,33120,1,'0xa9059cbb...0001','0xC12e9A9F8b7C9E2d4a1F37bB8d3a0F6d2D5f8c2a'),
				('0xeab732db75a148386f8fcab8d97885691e594bb6d82ed8bcd7bc5a72a9888bcd','2025-01-05 11:18:57','0x7AcB5A3fF0A9e21E65c5D98617B8b8F3D30dA11c','0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B',0.014,18000000000,50231,1,'0x60806040','0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B'),
				('0xa4e5d24097c082e2e725c75c91d6725860469a5f402b5d6ff698496814a61211','2025-01-05 14:29:31','0x1F4A88F5C48eBe76A3909E77efE33B4134d0B0E3','0xB33f45A6Dc6c47Aa0b5a5E2a5F01d4b2e9C7b434',0.07,24000000000,61821,1,'0xa9059cbb...0048','0xB33f45A6Dc6c47Aa0b5a5E2a5F01d4b2e9C7b434'),
				('0xf36d0b57ddc3129ebc774674bbdb8b07e143f0a0bb44bb1e1191bbdf83e9f4cd','2025-01-06 08:14:13','0xbF381a6F0b6B118CEd5d8438DFe558bAFe386c41','0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B',0.2,19900000000,59999,0,'0x095ea7b3...ffff','0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B'),
				('0x6765d094a117c344d0bea8fbc77adb172ad126c24b2c8b1da8610e215b8d8b27','2025-01-06 11:32:16','0x32D3c7bc676DBda3321A966C73c0008ef8cD31A0','0xC12e9A9F8b7C9E2d4a1F37bB8d3a0F6d2D5f8c2a',0.9,35000000000,84512,1,'0x60806040','0xC12e9A9F8b7C9E2d4a1F37bB8d3a0F6d2D5f8c2a'),
				('0x7196f69e1d9323d69b7bb9b4755de7dd429bc481b41fac1f02d52df2d71af98d','2025-01-06 15:44:29','0x7AcB5A3fF0A9e21E65c5D98617B8b8F3D30dA11c','0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B',1.1,29000000000,72000,1,'0xa9059cbb...','0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B'),
				('0x8fe4cd90121122bcd1f66eba98144c091b7a50680ee00e2df72addd6f6f02871','2025-01-07 09:33:18','0xa992114F8D43dD1a0B087E32B7F25A1af279b109','0xB33f45A6Dc6c47Aa0b5a5E2a5F01d4b2e9C7b434',0.0025,15500000000,45118,1,'0x60806040','0xB33f45A6Dc6c47Aa0b5a5E2a5F01d4b2e9C7b434'),
				('0x91f0a27b0ba7e9044b6a00deb377fd8c200358be30c83ce2671edf439fc5e30f','2025-01-07 13:12:09','0x1F4A88F5C48eBe76A3909E77efE33B4134d0B0E3','0xC12e9A9F8b7C9E2d4a1F37bB8d3a0F6d2D5f8c2a',0.04,20000000000,53211,1,'0x095ea7b3','0xC12e9A9F8b7C9E2d4a1F37bB8d3a0F6d2D5f8c2a'),
				('0xd3c1a8fc410408d0c9bf335e4a4da972fa614862bf4cf43d9a58a96ea7f86cfb','2025-01-07 16:41:55','0xbF381a6F0b6B118CEd5d8438DFe558bAFe386c41','0xB33f45A6Dc6c47Aa0b5a5E2a5F01d4b2e9C7b434',3.0,40000000000,94000,1,'0xa9059cbb...','0xB33f45A6Dc6c47Aa0b5a5E2a5F01d4b2e9C7b434'),
				('0x04e1f7e808b243d4ae40e6689dc98823d32b901d71dd3f0d5c2a78f4101c067c','2025-01-08 10:14:44','0x7AcB5A3fF0A9e21E65c5D98617B8b8F3D30dA11c','0xC12e9A9F8b7C9E2d4a1F37bB8d3a0F6d2D5f8c2a',0.03,21000000000,61234,1,'0xa9059cbb...','0xC12e9A9F8b7C9E2d4a1F37bB8d3a0F6d2D5f8c2a');

		-- Example ContractEvents (map a few transactions to events)
		insert into ContractEvents (ContractAddress, EventTypeCode, BlockNumber, BlockTimeStamp, TxHash, fromAddress, ToAddress, Amount, Details)
		values	('0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B',1,17654321,'2025-01-02 14:22:11','0x58e1c3b4f7a28c7e743ccfe89d8d9b393a7fcbf49b13f52399b43813fe55a1e1','0x7AcB5A3fF0A9e21E65c5D98617B8b8F3D30dA11c','0xA94f...','0.035','Transfer to VaultX'),
					('0xB33f45A6Dc6c47Aa0b5a5E2a5F01d4b2e9C7b434',3,17654500,'2025-01-03 08:22:55','0xc389257de7bde0b0b4372841cfb59f9c65e43bb1e5e2194e1738fbbec8b35c10','0x32D3c7...','0xB33f...','1.25','Contract creation / init');

		-- ContractEventLinks (link the event ids to contract)
		insert into ContractEventLinks (ContractAddress, EventId) 
		values	('0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B',1),
				('0xB33f45A6Dc6c47Aa0b5a5E2a5F01d4b2e9C7b434',2);


		-- ContractAuditors
		insert into ContractAuditors (ContractAddress, AuditorId, DurationMinutes)
		values	('0xA94f5374Fce5edBC8E2a8697C15331677e6EbF0B', 1, 90),
				('0xC12e9A9F8b7C9E2d4a1F37bB8d3a0F6d2D5f8c2a', 3, 120),
				('0xB33f45A6Dc6c47Aa0b5a5E2a5F01d4b2e9C7b434', 2, 60),
				('0xB33f45A6Dc6c47Aa0b5a5E2a5F01d4b2e9C7b434', 4, 60),
				('0xC12e9A9F8b7C9E2d4a1F37bB8d3a0F6d2D5f8c2a', 5, 60),
				('0xC12e9A9F8b7C9E2d4a1F37bB8d3a0F6d2D5f8c2a', 2, 90);


		/* ================================================
	   Atualização de totais da tabela Wallets
	   - TotalSent: soma de todos os valores enviados pela carteira
	   - TotalReceived: soma de todos os valores recebidos pela carteira
	   - TotalInteractions: número total de transações enviadas
	   ================================================ */

		/* Criacao de  uma CTE (Common Table Expression) para calcular os totais de cada wallet de forma agregada */
			with WalletAggregates 
			as (
				 select lower(fromAddress) WalletAddress,   -- Endereço da carteira em lowercase para evitar problemas de case
						sum(Amount) TotalSent,              -- Soma de todos os valores enviados
						count(*) TotalInteractions          -- Contagem de todas as transações enviadas
				 from ContractTransactions
				 group by lower(fromAddress)
				),
				ReceivedAggregates as (
					 select lower(ToAddress) as WalletAddress,     -- Endereço da carteira em lowercase
							sum(Amount) as TotalReceived            -- Soma de todos os valores recebidos
					 from ContractTransactions
					 group by lower(ToAddress)
				)

		/* Atualizacao da tabela Wallets com os totais calculados nas CTEs */
				update w
				set	w.TotalSent = isnull(a.TotalSent, 0),          -- Se não houver transações, define 0
					w.TotalReceived = isnull(r.TotalReceived, 0),  -- Se não houver recebimentos, define 0
					w.TotalInteractions = isnull(a.TotalInteractions, 0) -- Se não houver transações, define 0
				from Wallets w
				left join WalletAggregates a on a.WalletAddress = lower(w.WalletAddress)  -- Liga ao total enviado e contagem
				left join ReceivedAggregates r on r.WalletAddress = lower(w.WalletAddress) -- Liga ao total recebido


	