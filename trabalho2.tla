------------------------------ MODULE trabalho2 ------------------------------
(*Kauan Henrique Werlich - Trabalho Batalha RPG - Métodos Formais 2024/01*)

EXTENDS Naturals, Sequences

CONSTANTS
    MONSTER_HP,         \* Pontos de vida iniciais do monstro
    CHARACTER_HP,       \* Pontos de vida iniciais dos personagens (exceto o bárbaro)
    BARBARIAN_HP,       \* Pontos de vida iniciais do bárbaro
    MONSTER_DAMAGE,     \* Dano do ataque do monstro
    MONSTER_FIRST_DAMAGE, \* Dano do ataque do monstro no primeiro turno
    CHARACTER_DAMAGE    \* Dano do ataque dos personagens

TurnOrders ==
    << <<0, 1, 2, 3>>, <<0, 1, 3, 2>>, <<0, 2, 1, 3>>, <<0, 2, 3, 1>>, <<0, 3, 1, 2>>, <<0, 3, 2, 1>>,
       <<1, 0, 2, 3>>, <<1, 0, 3, 2>>, <<1, 2, 0, 3>>, <<1, 2, 3, 0>>, <<1, 3, 0, 2>>, <<1, 3, 2, 0>>,
       <<2, 0, 1, 3>>, <<2, 0, 3, 1>>, <<2, 1, 0, 3>>, <<2, 1, 3, 0>>, <<2, 3, 0, 1>>, <<2, 3, 1, 0>>,
       <<3, 0, 1, 2>>, <<3, 0, 2, 1>>, <<3, 1, 0, 2>>, <<3, 1, 2, 0>>, <<3, 2, 0, 1>>, <<3, 2, 1, 0>> >>

VARIABLES
    monster_hp,         \* Pontos de vida do monstro
    mage_hp,            \* Pontos de vida do mago
    cleric_hp,          \* Pontos de vida do clérigo
    barbarian_hp,       \* Pontos de vida do bárbaro
    monster_paralyzed,  \* Se o monstro está paralisado
    mage_paralyzed,     \* Se o mago está paralisado
    cleric_paralyzed,   \* Se o clérigo está paralisado
    barbarian_paralyzed,\* Se o bárbaro está paralisado
    cleric_immunity,    \* Se os personagens estão imunes devido à habilidade do clérigo
    monster_taunted,    \* Se o monstro está provocado pelo bárbaro
    turn,               \* Contador de turnos
    last_turn_info,      \* Informações sobre o último turno
    turn_order

ChooseRandomTurnOrder ==
    LET n == Len(TurnOrders)
    IN TurnOrders[1 + (turn % n)]

Init ==
    /\ monster_hp = MONSTER_HP
    /\ mage_hp = CHARACTER_HP
    /\ cleric_hp = CHARACTER_HP
    /\ barbarian_hp = BARBARIAN_HP
    /\ monster_paralyzed = FALSE
    /\ mage_paralyzed = FALSE
    /\ cleric_paralyzed = FALSE
    /\ barbarian_paralyzed = FALSE
    /\ cleric_immunity = FALSE
    /\ monster_taunted = FALSE
    /\ turn = 0
    /\ last_turn_info = ""
    /\ turn_order = ChooseRandomTurnOrder



MAX(a, b) == IF a > b THEN a ELSE b

MonsterTurn ==
    IF ~monster_paralyzed THEN 
        LET damage == IF cleric_immunity THEN 0 ELSE IF turn = 0 THEN MONSTER_FIRST_DAMAGE ELSE MONSTER_DAMAGE
        IN LET action == CHOOSE a \in {"attack", "paralyze"}: TRUE
        IN IF action = "attack" THEN
            IF monster_taunted THEN
                /\ barbarian_hp' = MAX(barbarian_hp - damage, 0)  \* Update the barbarian's HP after the monster's attack
                /\  IF barbarian_hp' = 0 THEN
                        /\ last_turn_info' = "Monster defeated the barbarian"
                        /\ UNCHANGED <<mage_hp, cleric_hp, monster_paralyzed, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
                    ELSE
                        /\ last_turn_info' = "Monster attacked"
                        /\ UNCHANGED <<mage_hp, cleric_hp, monster_paralyzed, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
            ELSE
                LET valid_targets == {t \in {"mage", "cleric", "barbarian"} : 
                    (t = "mage" /\ mage_hp > 0) \/ 
                    (t = "cleric" /\ cleric_hp > 0) \/ 
                    (t = "barbarian" /\ barbarian_hp > 0)}
                IN IF valid_targets = {} THEN
                    /\ last_turn_info' = "No valid target for monster attack"
                    /\ UNCHANGED <<mage_hp, cleric_hp, barbarian_hp, monster_hp, monster_paralyzed, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
                ELSE
                    LET c == CHOOSE ch \in valid_targets: TRUE
                    IN IF c = "mage" THEN
                        /\ mage_hp' = MAX(mage_hp - damage, 0)  \* Update the mage's HP after the monster's attack
                        /\  IF mage_hp' = 0 THEN
                                /\ last_turn_info' = "Monster defeated the mage"
                                /\ UNCHANGED <<cleric_hp, barbarian_hp, monster_hp, monster_paralyzed, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
                            ELSE
                                /\ last_turn_info' = "Monster attacked"
                                /\ UNCHANGED <<cleric_hp, barbarian_hp, monster_hp, monster_paralyzed, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
                    ELSE IF c = "cleric" THEN
                        /\ cleric_hp' = MAX(cleric_hp - damage, 0)  \* Update the cleric's HP after the monster's attack
                        /\  IF cleric_hp' = 0 THEN
                                /\ last_turn_info' = "Monster defeated the cleric"
                                /\ UNCHANGED <<mage_hp, barbarian_hp, monster_hp, monster_paralyzed, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
                            ELSE
                                /\ last_turn_info' = "Monster attacked"
                                /\ UNCHANGED <<mage_hp, barbarian_hp, monster_hp, monster_paralyzed, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
                    ELSE
                        /\ barbarian_hp' = MAX(barbarian_hp - damage, 0)  \* Update the barbarian's HP after the monster's attack
                        /\  IF barbarian_hp' = 0 THEN
                                /\ last_turn_info' = "Monster defeated the barbarian"
                                /\ UNCHANGED <<mage_hp, cleric_hp, monster_hp, monster_paralyzed, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
                            ELSE
                                /\ last_turn_info' = "Monster attacked"
                                /\ UNCHANGED <<mage_hp, cleric_hp, monster_hp, monster_paralyzed, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
        ELSE
            LET valid_targets == {t \in {"mage", "cleric", "barbarian"} : 
                (t = "mage" /\ mage_hp > 0) \/ 
                (t = "cleric" /\ cleric_hp > 0) \/ 
                (t = "barbarian" /\ barbarian_hp > 0)}
            IN IF valid_targets = {} THEN
                /\ last_turn_info' = "No valid target for monster paralyze"
                /\ UNCHANGED <<mage_hp, cleric_hp, barbarian_hp, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted, monster_paralyzed>>
            ELSE
                LET c == CHOOSE ch \in valid_targets: TRUE
                IN IF c = "mage" THEN
                    /\ mage_paralyzed' = TRUE  \* Paralyze the mage
                    /\ last_turn_info' = "Monster paralyzed the mage"
                    /\ UNCHANGED <<cleric_hp, barbarian_hp, monster_hp, monster_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
                ELSE IF c = "cleric" THEN
                    /\ cleric_paralyzed' = TRUE  \* Paralyze the cleric
                    /\ last_turn_info' = "Monster paralyzed the cleric"
                    /\ UNCHANGED <<mage_hp, barbarian_hp, monster_hp, monster_paralyzed, mage_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
                ELSE
                    /\ barbarian_paralyzed' = TRUE  \* Paralyze the barbarian
                    /\ last_turn_info' = "Monster paralyzed the barbarian"
                    /\ UNCHANGED <<mage_hp, cleric_hp, monster_hp, monster_paralyzed, mage_paralyzed, cleric_paralyzed, cleric_immunity, monster_taunted>>
    ELSE IF monster_hp > 0 THEN 
        /\ last_turn_info' = "Monster is paralyzed"
        /\ monster_paralyzed' = FALSE
        /\ UNCHANGED <<mage_hp, cleric_hp, barbarian_hp, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
    ELSE 
        /\ last_turn_info' = "Monster is dead"
        /\ UNCHANGED <<mage_hp, cleric_hp, barbarian_hp, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted, monster_paralyzed>>

MageTurn ==
    IF mage_hp > 0 /\ ~mage_paralyzed THEN
        /\ LET action == CHOOSE a \in {"attack", "remove_paralysis", "paralyze"}: TRUE
           IN IF action = "attack" THEN
               /\ monster_hp' = MAX(monster_hp - CHARACTER_DAMAGE, 0)  \* Atualiza os pontos de vida do monstro após o ataque do mago
               /\ IF monster_hp' = 0 THEN
                     /\ last_turn_info' = "Mage defeated the monster"
                     /\ UNCHANGED <<monster_paralyzed, mage_hp, cleric_hp, barbarian_hp, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
                  ELSE
                     /\ last_turn_info' = "Mage attacked"
                     /\ UNCHANGED <<monster_paralyzed, mage_hp, cleric_hp, barbarian_hp, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
           ELSE IF action = "remove_paralysis" /\ (cleric_paralyzed \/ barbarian_paralyzed) THEN
               LET c == CHOOSE ch \in {"cleric", "barbarian"}: TRUE
               IN IF c = "cleric" THEN
                   /\ cleric_paralyzed' = FALSE
                   /\ last_turn_info' = "Mage removed paralysis from cleric"
                   /\ UNCHANGED <<mage_hp, cleric_hp, barbarian_hp, monster_hp, mage_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
               ELSE
                   /\ barbarian_paralyzed' = FALSE
                   /\ last_turn_info' = "Mage removed paralysis from barbarian"
                   /\ UNCHANGED <<mage_hp, cleric_hp, barbarian_hp, monster_hp, mage_paralyzed, cleric_paralyzed, cleric_immunity, monster_taunted>>
           ELSE
               /\ monster_paralyzed' = TRUE  \* Paralisa o monstro
               /\ last_turn_info' = "Mage paralyzed the monster"
               /\ UNCHANGED <<mage_hp, cleric_hp, barbarian_hp, monster_hp, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
    ELSE IF mage_hp > 0 THEN 
        /\ last_turn_info' = "Mage is paralyzed"
        /\ UNCHANGED <<monster_paralyzed, mage_hp, cleric_hp, barbarian_hp, monster_hp, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
    ELSE 
        /\ last_turn_info' = "Mage is dead"
        /\ UNCHANGED <<monster_paralyzed, mage_hp, cleric_hp, barbarian_hp, monster_hp, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>

ClericTurn ==
    IF cleric_hp > 0 /\ ~cleric_paralyzed THEN
        /\ LET action == CHOOSE a \in {"attack", "remove_paralysis", "immunize"}: TRUE
           IN IF action = "attack" THEN
               /\ cleric_immunity' = FALSE
               /\ monster_hp' = MAX(monster_hp - CHARACTER_DAMAGE, 0)  \* Atualiza os pontos de vida do monstro após o ataque do clérigo
               /\ IF monster_hp' = 0 THEN
                     /\ last_turn_info' = "Cleric defeated the monster"
                     /\ UNCHANGED <<monster_paralyzed, mage_hp, barbarian_hp, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
                  ELSE
                     /\ last_turn_info' = "Cleric attacked"
                     /\ UNCHANGED <<monster_paralyzed, mage_hp, barbarian_hp, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
           ELSE IF action = "remove_paralysis" /\ (mage_paralyzed \/ barbarian_paralyzed) THEN
               LET c == CHOOSE ch \in {"mage", "barbarian"}: TRUE
               IN IF c = "mage" THEN
                   /\ cleric_immunity' = FALSE
                   /\ mage_paralyzed' = FALSE
                   /\ last_turn_info' = "Cleric removed paralysis from mage"
               ELSE
                   /\ cleric_immunity' = FALSE
                   /\ barbarian_paralyzed' = FALSE
                   /\ last_turn_info' = "Cleric removed paralysis from barbarian"
           ELSE IF action = "immunize" THEN
               /\ cleric_immunity' = TRUE
               /\ last_turn_info' = "Cleric immunized"
               /\ UNCHANGED <<monster_hp>>
           ELSE
               /\ cleric_immunity' = FALSE
               /\ last_turn_info' = "Cleric did nothing"
        /\ UNCHANGED <<cleric_hp, mage_hp, barbarian_hp, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
    ELSE IF cleric_hp > 0 THEN 
        /\ last_turn_info' = "Cleric is paralyzed"
        /\ cleric_immunity' = FALSE
        /\ UNCHANGED <<monster_paralyzed, cleric_hp, monster_hp, mage_hp, barbarian_hp, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
    ELSE
        /\ last_turn_info' = "Cleric is dead"
        /\ UNCHANGED <<monster_paralyzed, cleric_hp, monster_hp, mage_hp, barbarian_hp, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>

BarbarianTurn ==
    IF barbarian_hp > 0 /\ ~barbarian_paralyzed THEN
        /\ LET action == CHOOSE a \in {"attack", "remove_paralysis", "taunt"}: TRUE
           IN IF action = "attack" THEN
               /\ monster_hp' = MAX(monster_hp - CHARACTER_DAMAGE, 0)  \* Atualiza os pontos de vida do monstro após o ataque do bárbaro
               /\ IF monster_hp' = 0 THEN
                     /\ last_turn_info' = "Barbarian defeated the monster"
                     /\ UNCHANGED <<barbarian_paralyzed, monster_paralyzed, mage_hp, cleric_hp, mage_paralyzed, cleric_paralyzed, cleric_immunity, monster_taunted>>
                  ELSE
                     /\ last_turn_info' = "Barbarian attacked"
                     /\ UNCHANGED <<barbarian_paralyzed, monster_paralyzed, mage_hp, cleric_hp, mage_paralyzed, cleric_paralyzed, cleric_immunity, monster_taunted>>
           ELSE IF action = "remove_paralysis" THEN
               LET c == CHOOSE ch \in {"mage", "cleric"}: TRUE
               IN IF c = "mage" THEN
                   /\ mage_paralyzed' = FALSE
                   /\ last_turn_info' = "Barbarian removed paralysis from mage"
               ELSE
                   /\ cleric_paralyzed' = FALSE
                   /\ last_turn_info' = "Barbarian removed paralysis from cleric"
               /\ UNCHANGED <<mage_hp, cleric_hp, barbarian_hp, cleric_immunity, monster_taunted>>
           ELSE
               /\ monster_taunted' = TRUE
               /\ last_turn_info' = "Barbarian taunted"
               /\ UNCHANGED <<monster_hp, mage_hp, cleric_hp, barbarian_hp, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity>>
        /\ UNCHANGED <<barbarian_hp>>
    ELSE IF barbarian_hp > 0 THEN 
        /\ last_turn_info' = "Barbarian is paralyzed"
        /\ UNCHANGED <<barbarian_hp, monster_hp, mage_hp, cleric_hp, barbarian_hp, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>
    ELSE 
        /\ last_turn_info' = "Barbarian is dead"
        /\ UNCHANGED <<barbarian_hp, monster_hp, mage_hp, cleric_hp, barbarian_hp, mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted>>

GameOver == (monster_hp = 0 \/ (mage_hp = 0 /\ cleric_hp = 0 /\ barbarian_hp = 0))

Next ==
    LET current_turn == turn_order[(turn % 4) + 1]
    IN \/ (current_turn = 0 /\ MonsterTurn /\ ~GameOver)
       \/ (current_turn = 1 /\ MageTurn /\ ~GameOver)
       \/ (current_turn = 2 /\ ClericTurn /\ ~GameOver)
       \/ (current_turn = 3 /\ BarbarianTurn /\ ~GameOver)
       \/ (GameOver /\ UNCHANGED <<monster_hp, mage_hp, cleric_hp, barbarian_hp, monster_paralyzed, 
            mage_paralyzed, cleric_paralyzed, barbarian_paralyzed, cleric_immunity, monster_taunted, 
            last_turn_info, turn_order>>)
    /\ turn' = turn + 1
    /\ IF (turn' % 4 = 0) THEN
           turn_order' = ChooseRandomTurnOrder
       ELSE
           turn_order' = turn_order
    /\ turn <= 1000


(***************************************************************************)
(*                              Invariantes                                *)
(***************************************************************************)
Inv1 == monster_hp > 0
Inv2 == mage_hp > 0 /\ cleric_hp > 0 /\ barbarian_hp > 0

=============================================================================

(***
#.cfg
INIT 
Init 
NEXT 
Next
INVARIANTS Inv1
CONSTANTS
    MONSTER_HP = 100
    CHARACTER_HP = 20
    BARBARIAN_HP = 150
    MONSTER_DAMAGE = 20
    MONSTER_FIRST_DAMAGE = 10
    CHARACTER_DAMAGE = 10
***)
