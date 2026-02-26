		-------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------------------------------------
		/*							 Vistas Adaptadas ao SmartContractMonotoring										 */
		-------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------------------------------------
		use SmartContractMonitoring
		go
		/* Vista 1
			  
			  Vista inspirada na Vista 1 do PDF (percursos lotados vs nunca lotados),
			   adaptada a base de dados SmartContractMonitoring.

			   Objetivo:
			   - Mostrar contratos que tiveram pelo menos uma interação fully booked
			   - Mostrar contratos que nunca tiveram uma interação fully booked
			   - Mostrar informações úteis: nome, risco, participantes, max participantes

		*/
		create view vw_ContractFullyBookedStatus
		as
		select sc.ContractAddress, sc.ContractName, sc.RiskLevelCode,
			   ui.TotalParticipants, ui.MaxParticipants,
			   case when exists ( select 1 
								  from UserInteractions ui2 
								  where ui2.ContractAddress = sc.ContractAddress
								  and ui2.TotalParticipants = ui2.MaxParticipants
								  and ui2.InteractionState = 1 )
					then 1 else 0
				end as FullyBooked
		from SmartContracts sc
		left join UserInteractions ui on sc.ContractAddress = ui.ContractAddress
		group by sc.ContractAddress, sc.ContractName, sc.RiskLevelCode,
			     ui.TotalParticipants, ui.MaxParticipants

		go

		select * from vw_ContractFullyBookedStatus
		go
		/* Vista 2
			  
		  Esta vista resume todas as interações realizadas no 1.º trimestre de 2025
		  (entre 01/01/2025 e 31/03/2025), agregando os resultados por:
			 • Tipo de Interação (InteractionName)
			 • Nível de Risco associado ao contrato (RiskLevelCode)

		  Pergunta DE NEGÓCIO QUE RESPONDE:
		  "Quantas interações ocorreram por tipo de interação e nível de risco,
		  e quantos participantes no total estiveram envolvidos, durante o Q1 2025?"

		*/

		create view vw_InteractionSummaryQ1_2025 
		as
		select it.InteractionName, sc.RiskLevelCode,
			   count(ui.InteractionId) NumInteractions,
			   sum(ui.TotalParticipants) TotalParticipants
		from InteractionTypes it
		left join UserInteractions ui on it.InteractionTypeId = ui.InteractionTypeCode
		left join SmartContracts sc on ui.ContractAddress = sc.ContractAddress
		where ui.ScheduledAt between '2025-01-01' and '2025-04-01'
		group by it.InteractionName, sc.RiskLevelCode

		go

		select * from vw_InteractionSummaryQ1_2025
		go