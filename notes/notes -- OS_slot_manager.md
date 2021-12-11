# CODING NOTES -- OS_slot_manager

## Some things to take into account

**Suggestion sending**. The suggestion should be picked immediately, because the module publishes a new suggestion depending on the situation *at the current frame*, so the suggestion can change quickly. 

**reliability**. Sometime the sensor doesn't work well, which is a realistic situation: in the real environment, sensors are not perfect, and the color detection could be not reliable sometimes. The suggestion is published only if the module *is sure to have a coherent situation*. 

## Shared Interface

```
-- HANDLER
slot_manager = sim.getObjectHandle( "OS_slot_manager" )

-- DATA STRUCTURE : suggestion
msg = {
	slot= , --> the suggested slot
	pick_point_handle= --> the pick point of the object (deprecated)
}
-- empty message : (-1, -1)

-- (READ ONLY)
-- read the next suggestion
data = sim.unpackTable(sim.readCustomDataBlock( slot_manager, "OS_slot_manager_shared" ) )
```



## NUOVA VERSIONE DEL MODULO OS_slot_manager

- deve mantenere sempre la stessa interfaccia

il sensore di prossimità della slot *è più affidabile* del sensore ottico, che ogni tanto fa cilecca. Usa un index filter. 
RILEVAZIONE: precedenza al sensore di prossimità della slot. 
DETECTION: una volta capito che la slot è occupata a partire dal sensore di prossimità, tenta di trovare il tipo dell'oggetto. Se ci si riesce, la slot è occupata realmente, altrimenti scarta la misurazione
BEST CHOICE: 
	1. scarta tutte le misurazioni con y negative
	2. prendi la misurazione con y più piccolo e positivo

Info per l'implementazione:
	handle slot ensor
	handle sensori ottici

aggiorna lo stato di TUTTI i sensori
indice <-- -1
rileva le slot occupate dal sensore di prossimità --> OVVERO trova gli indici
	se la lista è vuota, break
	se gli indici sono gli stessi di prima, passa avanti (nessuna nupva misurazione)
confronta le rilevazioni con quelle dei sensori ottici (almeno i flag) --> OVVERO filtra gli indici 
	se la lista è vuota, break
scarta tutti gli indici con y negativo
	se la lista è vuota, break
	se nella lista c'è un solo elemento, allora
		indice <-- quell'elemento, e break
ordina la lista in base ad una metrica (una funzione) e prendi il primo della lista
	indice <-- il primo della lista
pubblica l'indice.

PUBBLICAZIONE INDICE:
	se indice == -1 allora pubblica un messaggio vuoto
	altrimenti, pubblica il messaggio con tutte le informazioni riguardo questo indice

METRICA (minimization):
	una distanza "pesata": (x + alpha*y)
	la componente con y più basso "vince"
	default: alpha=3