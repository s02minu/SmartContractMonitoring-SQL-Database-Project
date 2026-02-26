		-------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------------------------------------
		/*							 Pesquisas Adaptadas ao SmartContractMonotoring										 */
		-------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------------------------------------------------------------------------
		use SmartContractMonitoring
		go
		/* Pesquisa 1
			Quais auditores, até agora, receberam menos de 500€ por todas as auditorias que fizeram?
			Isto é útil para identificar auditores com pouca remuneração acumulada 
			(p.ex. para oferecer mais trabalho ou rever preços).
		*/
		select * from Auditors
		select * from ContractAuditors
		
		select a.AuditorName, 
			   sum(ca.DurationMinutes/60 * a.HourlyRate) TotalEarning,
			   count(ca.Id) NumberAudits
		from Auditors a, ContractAuditors ca
		where a.AuditorId = ca.AuditorId
		group by a.AuditorName
		having  sum(ca.DurationMinutes/60 * a.HourlyRate)  < 500
		order by 3
		

		/* Pesquisa 2
			Quais são as 3 carteiras que mais tiverma mais interações, quanto enviaram (TotalSent), 
			quanto tempo total passaram com as  interações e qual a quantodade de ETH enviado por minuto?
			Isto ajuda a identificar utilizadores altamente ativos e relacionar atividade com volume transferido.
		*/

		select * from Wallets
		select * from UserInteractions
		select * from WalletInteractions

		select 
		top 3 w.WalletAddress, w.TotalInteractions, w.TotalSent,
			  sum(ui.DurationMinutes) TotalMinutes,
			  case when sum(ui.DurationMinutes) = 0 then 0
			  else round(cast(w.TotalSent as numeric(20,8)) / sum(ui.DurationMinutes), 8) 
			  end as  ETH_per_Minute
		from wallets w, WalletInteractions wi, UserInteractions ui
		where w.WalletAddress = wi.WalletAddress
		and wi.InteractionId = ui.InteractionId
		group by w.WalletAddress, w.TotalInteractions, w.TotalSent
		order by 2, 3 desc

		
		
		/* Pesquisa 3
			Quais eventos associados a contratos resultaram em transacções falhadas (ou potencialmente suspeitas)?
			Serve para triagem de eventos que exigem investigação (p.ex. tentativas de exploit, reverts, falhas de execução).
		*/

		select ce.EventId, ce.ContractAddress, et.EventName, ce.BlockTimeStamp, ce.TxHash,
			   ce.FromAddress, ce.ToAddress, ce.Amount, ts.StatusName
		from ContractEvents ce
		left join EventTypes et on ce.EventTypeCode = et.EventTypeCode
		left join SmartContracts sc on ce.ContractAddress = sc.ContractAddress
		left join ContractTransactions ct on sc.ContractAddress = ct.ContractAddress
		left join TransactionStatus ts on ct.StatusCode = ts.StatusCode
		where ct.StatusCode = 0
		order by 9, 4 desc


		/* Pesquisa 4
			Como se distribuem as interações (quantidade e participação) por nível de risco dos contratos, 
			e que auditor (se aplicável) esteve responsável por essas interações?
			Isso ajuda a entender se contratos de maior risco têm mais/menos auditorias ou interações maiores, 
			e o envolvimento dos auditores nesses níveis.
		*/


		select rl.RiskDescription, a.AuditorName, 
			   count(ui.InteractionId) NumInteractions ,
			   coalesce(sum(ui.TotalParticipants), 0) TotalParticipants
		from SmartContracts sc
		join RiskLevel rl on sc.RiskLevelCode = rl.RiskLevelCode
		left join UserInteractions ui on sc.ContractAddress = ui.ContractAddress
		left join ContractAuditors ca on ca.ContractAddress = sc.ContractAddress
		join Auditors a on ca.AuditorId = a.AuditorId
		group by rl.RiskDescription, a.AuditorName
		