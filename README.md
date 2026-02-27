# Smart ContractM onitoring — SQL Database Project

> Academic project developed for UFCD 10797 – Gestão e Armazenamento de Dados  
> IEFP – Instituto de Emprego e Formação Profissional, Viseu | Aprend+ 02/2025

## Overview

This project reimagines the original "Caminhadas Pedestres" database task by building a 
**Smart Contract Monitoring System** inspired by the Ethereum blockchain ecosystem.

Instead of managing hiking trails, this database models and audits the interactions between 
wallets, smart contracts, transactions, and auditors — simulating what a real blockchain analytics platform might look like off-chain.

> **Note:** Some design decisions were adapted to fit the relational database requirements of 
> the course task. A real blockchain system would handle certain data differently on-chain.

---

## Why Blockchain?

The original task asked for a database to manage hiking routes and participants.  
I chose to map those concepts to the Ethereum ecosystem:

| Caminhadas Pedestres | SmartContractMonitoring |
|---|---|
| Percursos | Smart Contracts |
| Guias Pedestres | Auditors |
| Caminhadas | User Interactions |
| Pessoas Inscritas | Wallets |
| Inscritas | Wallet Interactions |
| Estado de Conservação | Risk Level |

---

## Database Schema

The database `SmartContractMonitoring` contains the following tables:
<img width="698" height="803" alt="DiagramaSmartContractMonitoring" src="https://github.com/user-attachments/assets/9162d88e-cb2f-4b99-9336-a36d741301e1" />


### Reference / Lookup Tables
- **TransactionStatus** – Possible states for a transaction (Success, Failed, Reverted)
- **EventTypes** – Types of events emitted by smart contracts (Transfer, Approval, Mint…)
- **InteractionTypes** – Categories of user interactions (Read, Write, Transfer, Approve)
- **RiskLevel** – Risk classification for smart contracts (Low, Medium, High)

### Core Tables
- **SmartContracts** – Central table; each row is a monitored Ethereum contract
- **Wallets** – Ethereum addresses active in the ecosystem, with aggregated metrics
- **Auditors** – Off-chain professionals responsible for contract security reviews
- **Admins** – Platform administrators managing the monitoring system

### Transaction & Event Tables
- **ContractTransactions** – Raw transaction data linked to contracts
- **ContractEvents** – Events emitted during transaction execution
- **ContractEventLinks** – Many-to-many bridge between contracts and events

### Relationship / Activity Tables
- **UserInteractions** – Organised interaction sessions linked to contracts (equivalent to *Caminhadas*)
- **WalletInteractions** – Tracks which wallets participated in each interaction
- **InteractionContract** – Maps which interaction types each contract supports
- **ContractAuditors** – Assigns auditors to contracts with duration and timestamp

---

## Queries

Four analytical queries were written to extract meaningful insights from the data:

**Query 1 — Auditors earning below €500**  
Identifies auditors with low accumulated earnings across all audits — useful for 
workload balancing or pricing reviews.  
Tables: `Auditors`, `ContractAuditors`
```sql
select a.AuditorName, 
	   sum(ca.DurationMinutes/60 * a.HourlyRate) TotalEarning,
	   count(ca.Id) NumberAudits
from Auditors a, ContractAuditors ca
where a.AuditorId = ca.AuditorId
group by a.AuditorName
having  sum(ca.DurationMinutes/60 * a.HourlyRate)  < 500
order by 3
```


**Query 2 — Top 3 most active wallets**  
Returns the 3 wallets with the most interactions, their total ETH sent, total time 
spent in interactions, and ETH sent per minute — useful for identifying power users 
or automated bots.  
Tables: `Wallets`, `WalletInteractions`, `UserInteractions`
```sql
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
```

**Query 3 — Failed transactions linked to contract events**  
Surfaces events associated with failed transactions, enabling triage of suspicious 
activity such as exploit attempts, reverts, or execution failures.  
Tables: `ContractEvents`, `EventTypes`, `SmartContracts`, `ContractTransactions`, `TransactionStatus`
```sql
select ce.EventId, ce.ContractAddress, et.EventName, ce.BlockTimeStamp, ce.TxHash,
	   ce.FromAddress, ce.ToAddress, ce.Amount, ts.StatusName
from ContractEvents ce
left join EventTypes et on ce.EventTypeCode = et.EventTypeCode
left join SmartContracts sc on ce.ContractAddress = sc.ContractAddress
left join ContractTransactions ct on sc.ContractAddress = ct.ContractAddress
left join TransactionStatus ts on ct.StatusCode = ts.StatusCode
where ct.StatusCode = 0
order by 9, 4 desc
```


**Query 4 — Interactions and auditors by risk level**  
Distributes interactions and participant counts by contract risk level, showing which 
auditors were involved — useful for understanding whether high-risk contracts receive 
proportionally more oversight.  
Tables: `SmartContracts`, `RiskLevel`, `UserInteractions`, `ContractAuditors`, `Auditors`
```sql
select rl.RiskDescription, a.AuditorName, 
	   count(ui.InteractionId) NumInteractions ,
	   coalesce(sum(ui.TotalParticipants), 0) TotalParticipants
from SmartContracts sc
join RiskLevel rl on sc.RiskLevelCode = rl.RiskLevelCode
left join UserInteractions ui on sc.ContractAddress = ui.ContractAddress
left join ContractAuditors ca on ca.ContractAddress = sc.ContractAddress
join Auditors a on ca.AuditorId = a.AuditorId
group by rl.RiskDescription, a.AuditorName
```


---

## Views

**View 1 — `vw_ContractFullyBookedStatus`**  
Inspired by the original task's "fully booked routes" concept. Shows which contracts 
had at least one fully booked interaction session and which never reached capacity.  
Useful for capacity planning and demand analysis.  
Tables: `SmartContracts`, `UserInteractions`
```sql
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
```

**View 2 — `vw_InteractionSummaryQ1_2025`**  
Summarises all interactions during Q1 2025 (January–March), grouped by interaction 
type and contract risk level — showing total sessions and total participants.  
Answers: *"Which interaction types were most active in Q1, and across which risk levels?"*  
Tables: `InteractionTypes`, `UserInteractions`, `SmartContracts`
```sql
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
```

---

## Stored Procedure

**`usp_InsertEventType`**  
Safely inserts a new event type into the `EventTypes` table. Before inserting, it 
validates that neither the `EventTypeCode` nor the `EventName` (case-insensitive) 
already exists. If either condition fails, a descriptive error is raised and the 
insert is aborted.
```sql
-- Example usage
exec usp_InsertEventType @code = 7, @name = 'Mint';
```
<img width="255" height="138" alt="image" src="https://github.com/user-attachments/assets/fa0ef9b4-088e-4247-9792-388e05191fe3" />

<img width="676" height="127" alt="image" src="https://github.com/user-attachments/assets/e990d858-307d-46db-9d48-cf60bbb2ace9" />


---

## Trigger

**`trg_InsertWalletInteraction`** — `INSTEAD OF INSERT` on `WalletInteractions`

This trigger enforces four business rules before allowing a wallet to join an interaction:

| Rule | Description |
|---|---|
| A — Referential integrity | The wallet must exist in the `Wallets` table |
| B — Referential integrity | The interaction must exist in `UserInteractions` |
| C — No duplicates | The wallet cannot join the same interaction twice |
| D — Capacity check | The interaction must still have available slots |

If a valid insertion passes all checks, it is committed and `TotalParticipants` 
in `UserInteractions` is automatically updated using a CTE aggregation.  
Descriptive error messages are raised for each specific failure case.

---

## Key SQL Features Used

- `PRIMARY KEY`, `FOREIGN KEY`, `IDENTITY`, `DEFAULT`, `BIT`
- `CHECK` constraints for data integrity
- **CTEs (Common Table Expressions)** for aggregated updates
- `INSTEAD OF` trigger with multi-rule validation and auto-update logic
- Stored procedure with duplicate-prevention and error handling
- Views for Q1 reporting and capacity analysis
- `LEFT JOIN`, `ISNULL`, `LOWER()`, `COALESCE`, `RAISERROR`, `TOP`

---

## How to Run

1. Open **SQL Server Management Studio (SSMS)** or any compatible SQL Server client
2. Run the scripts in this order:
   - `SmartContractMonitoring.sql` — Creates the database, all tables, and inserts sample data
   - `SmartContractMonitoring_Pesquisas.sql` — Analytical queries
   - `SmartContractMonitoring_Vistas.sql` — View definitions
   - `SmartContractMonitoring_Proc.sql` — Stored procedure
   - `SmartContractMonitoring_Trigger.sql` — Trigger definition and test cases

> Tested on **Microsoft SQL Server** (T-SQL syntax)

> **Tip:** The trigger file includes test insertions you can run step by step to validate 
> each error scenario (missing wallet, duplicate, capacity exceeded).

---

## Notes

- An attempt was made to fetch real Ethereum data via a public API, but access was 
  denied (HTTP 401). Sample data was generated with AI assistance to simulate 
  realistic blockchain activity.
- This project was developed independently as an alternative to the course's prescribed 
  theme, with approval to modify the proposed model.
- Some table designs (e.g. `UserInteractions`, `WalletInteractions`) do not reflect how 
  a real on-chain system would work, but were shaped to satisfy the relational database 
  requirements of the assignment.

---

## Author

**_so2minu_** 
---
Data Science and Information Management

