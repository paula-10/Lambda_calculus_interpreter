În cadrul acestei teme am realizat un interpretor de expresii lambda în Haskell.

O să definim o expresie lambda cu ajutorul următorului TDA:

data Lambda = Var String
            | App Lambda Lambda
            | Abs String Lambda
            
Variabilele sunt declarate de tipul String, pentru simplitate o să considerăm variabilă orice șir de caractere format numai din litere mici ale alfabetului englez.

1. Evaluation
Reminder:
redex - o expresie reductibilă, i.e. are forma (λx.e1 e2)
normal-form - expresie care nu mai poate fi redusa (nu contine niciun redex)

Evaluarea unei expresii lambda constă în realizarea de β-reducerii până ajungem la o expresie echivalentă în formă normală.Un detaliu de implementare este că înainte de a realiza β-reducerea, va trebui să rezolvăm posibilele coliziuni de nume.
Dacă am încerca să reducem un redex fără a face substituții textuale există riscul de a pierde întelesul original al expresiei.
Spre exemplu redex-ul: (λx.λy.(x  y) λx.y), ar fi redus la: λy.(λx.y  y). Acest efect nedorit are denumirea intuitivă de variable-capture: Variabila inițial liberă y
 a devenit legată după reducere.
Puteți observa că expresia și-a pierdut sensul original, pentru că y-ul liber din 
λx.y e acum bound de λy. din expresia în care a fost înlocuit.
Astfel, reducerea corectă ar fi: λa.(λx.y  a).
Pentru a detecta și rezolva variable capture, o să pregătim câteva funcții ajutătoare:
- funcția auxiliară vars care returnează o listă cu toate String-urile care reprezintă variabile într-o expresie.
- funcția auxiliară freeVars care returnează o listă cu toate String-urile care reprezintă variabile libere într-o expresie. (notă: dacă o variabilă este liberă în expresie în mai multe contexte, o să apară o singură dată în listă).
- funcția auxiliară newVars care primește o listă de String-uri și intoarce cel mai mic String lexicografic care nu apare în listă (e.g. new_vars [“a”, “b”, “c”] o să întoarcă “d”).
- funcția isNormalForm care verifică daca o expresie este în formă normală.
- funcția reduce care realizează β-reducerea unui redex luând în considerare și coliziunile de nume. Funcția primește redex-ul 'deconstruit' și returnează expresia rezultată.
reduce :: String -> Lambda -> Lambda -> Lambda
reduce x e_1 e_2 = undefined
-- oriunde apare variabila x în e_1, este inlocuită cu e_2

Acum că putem reduce un redex, vrem să reducem o expresie la forma ei normală. Pentru asta trebuie să implementăm o strategie de alegere a redex-ului care urmează să fie redus, și să o aplicăm până nu mai există niciun redex. În această temă o să implementăm 2 strategii: Normală și Aplicativă.
Normală: se alege cel mai exterior, cel mai din stânga redex
Aplicativă: se alege cel mai interior, cel mai din stânga redex
O să facem reducerea „step by step”, implementăm o funcție care reduce doar următorul redex comform unei strategii. Apoi aplicăm acesți pași până expresia rămasă este în formă normală. Functiile care ne vor ajuta sa implementam cele doua strategii sunt:
- funcția normalStep care aplică un pas de reducere după strategia Normală.
- funcția applicativeStep care aplică un pas de reducere după strategia Aplicativă.
- funcția simplify, care primeste o funcție de step și o aplică până expresia rămâne în formă normală, și întoarce o listă cu toți pași intermediari ai reduceri.

2. Parsing
Momentan putem să evaluăm expresii definite tot de noi sub formă de cod. Pentru a avea un interpretor funcțional, trebuie să putem lua expresii sub forma de șiruri de caractere și să le transformăm în TDA-uri (acest proces se numește parsare).
O gramatică pentru expresii lambda ar putea fi:
<lambda> ::= <variable> | '\' <variable> '.' <lambda> | (<lambda> <lambda>)
<variable> ::= <variable><alpha> | <alpha> 
<alpha> ::= 'a' | 'b' | 'c' | ... | 'z'

Funcția parseLambda parsează un String și returnează o expresie

Parserul care trebuie să îl implementați are definiția:
newtype Parser a = Parser {
    parse :: String -> Maybe(a, String)
}
Obervați că tipul care îl întoarce funcția de parsare este Maybe(a, String), el întoarce Nothing dacă nu a putut parsa expresia sau Just (x, s) dacă a parsat x, iar din String-ul original a rămas sufix-ul s.

3. Steps towards a programming language
Folosind parserul și evaluatorul anterior, putem să evaluăm orice rezultat computabil, expresiile lambda fiind suficient de expresive, însă este foarte greu să scrii astfel de expresii. Pentru a fi mai ușor de folosit, vrem să putem denumi anumite sub-expresii pentru a le putea refolosi ulterior. Pentru asta o să folosim conceptul de macro. Primul pas ar fi să extindem definiția unei expresii cu un constructor Macro care acceptă un String ca parametru (denumirea macro-ului). O să introducem și sintaxa: orice șir de caractere format numai din litere mari ale alfabetului englez si cifre e considerat un macro.

Câteva exemple de expresii cu macro-uri sunt: 
TRUE 
λx.FALSE 
λx(NOT λy.AND)

Pentru a putea folosi macro-uri, trebuie să introducem noțiunea de context computațional. Contextul în care evaluăm o expresie este pur și simplu un dicționar de nume de macro-uri și expresii pe care aceste nume le înlocuiesc. Astfel când evaluăm un macro, facem pur și simpu substituție textuală cu expresia găsită în dicționar.

În cazul în care nu găsim macro-ul în context, nu o să știm cum să evaluăm expresia, asa că am vrea să întoarcem o eroare. O să extindem tipul de date întors la Either String [Lambda] și o să întoarce Left în caz de eroare și Right în cazul în care evaluarea se termina cu succes.

Funcția simplifyCtx ia un context și o expresie care poate să conțină macro-uri, face substituțiile macro-urilor (sau returnează eroare dacă nu reușeste) și evaluează expresia rezultată folosind strategia de step primită.

Codul atunci când lucrezi cu Maybe sau Either poate să devina complicat dacă folosim case-uri pe toate variabilele, pentru a ușura lucrul cu ele există monade definite atât peste tipul de date Maybe cât și peste Either, poți folosi do notation să îți ușurezi viața.
funcția lookup este foarte utilă pentru lucrul cu dicționare (liste de perechi)
Ultimul pas ca să ne putem folosi de macro-uri e să găsim o metodă de a le defini. Pentru asta o sa definim conceptul de linie de cod:

data Line = Eval Lambda
          | Binding String Lambda
O linie de cod poate să fie ori o expresie lambda, ori o definiție de macro. Astfel daca o sa evaluam mai multe linii de cod, în expresii o sa ne putem folosi de macro-urile definite anterior.

Am modificat parser-ul astfel încât să parsez și expresii care conțin macro-uri.
Am implementat funcția parseLine care parseaza o linie de cod, dacă găsește erori o să întoarcă o eroare (sub formă de String).

4.Default Library
Acum că avem un interpretor funcțional pentru calcul lambda, hai să definim și câteva expresii uzuale, ca să le putem folosi ca un context default pentru interpretorul nostru (un fel de standard library).

În fișierul Default.hs sunt deja definiti câțiva combinatori. Definiții restul expresiilor.

Am definit ca expresii lambda câteva macro-uri utile pentru lucrul cu Booleene (TRUE, FALSE, AND, OR, NOT, XOR).

Am definit ca expresii lambda câteva macro-uri utile pentru lucrul cu perechi (PAIR, FIRST, SECOND).

Am definit ca expresii lambda câteva macro-uri utile pentru lucrul cu numere naturale (N0, N1, N2, SUCC, PRED, ADD, SUB, MULT).
