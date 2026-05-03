<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>Solitário Jucabel Pro</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #2c3e50; color: white; display: flex; flex-direction: column; align-items: center; min-height: 100vh; margin: 0; padding: 5px; box-sizing: border-box; overflow-x: hidden; }
        h1 { margin: 5px 0; font-size: 20px; text-shadow: 2px 2px 4px rgba(0,0,0,0.5); }
        button { background-color: #e74c3c; color: white; border: none; padding: 8px 16px; border-radius: 5px; cursor: pointer; font-size: 14px; margin-bottom: 5px; }

        #jogo { display: grid; grid-template-columns: repeat(7, 1fr); gap: 4px; width: 100%; max-width: 700px; margin-top: 5px; }
        
        /* ÁREA SUPERIOR - Onde diminuímos o tamanho */
        .area-superior { grid-column: span 7; display: grid; grid-template-columns: repeat(7, 1fr); gap: 4px; margin-bottom: 15px; align-items: start; }
        
        .espaco-vazio { background-color: rgba(255,255,255,0.1); border: 1px dashed rgba(255,255,255,0.3); border-radius: 4px; width: 100%; aspect-ratio: 2/3; display: flex; align-items: center; justify-content: center; font-size: 18px; color: rgba(255,255,255,0.3); position: relative; }

        /* CARTAS - Tamanho reduzido para o topo e base */
        .carta { background-color: white; color: black; border-radius: 4px; width: 100%; aspect-ratio: 2/3; display: flex; flex-direction: column; justify-content: space-between; padding: 3px; box-sizing: border-box; box-shadow: 1px 1px 4px rgba(0,0,0,0.3); border: 1px solid #999; cursor: pointer; position: relative; font-weight: bold; font-size: 12px; }
        .carta.vermelha { color: #e74c3c; }
        .carta.verso { background-color: #34495e; background-image: radial-gradient(#2c3e50 20%, transparent 20%); background-size: 5px 5px; color: transparent; border-color: #1a252f; }
        .carta .topo, .carta .base { display: flex; justify-content: flex-start; gap: 1px; line-height: 1; }
        .carta .base { transform: rotate(180deg); }
        .carta.selecionada { outline: 3px solid #f1c40f; z-index: 100; }

        /* MESA - Empilhamento */
        .pilha-mesa { position: relative; min-height: 250px; grid-row: 2; }
        .pilha-mesa .carta { position: absolute; top: 0; left: 0; }
        
        /* Ajuste da "Escadinha" das cartas na mesa */
        .pilha-mesa .carta:nth-child(1) { top: 0px; }
        .pilha-mesa .carta:nth-child(2) { top: 22px; }
        .pilha-mesa .carta:nth-child(3) { top: 44px; }
        .pilha-mesa .carta:nth-child(4) { top: 66px; }
        .pilha-mesa .carta:nth-child(5) { top: 88px; }
        .pilha-mesa .carta:nth-child(6) { top: 110px; }
        .pilha-mesa .carta:nth-child(7) { top: 132px; }
        .pilha-mesa .carta:nth-child(8) { top: 154px; }
        .pilha-mesa .carta:nth-child(9) { top: 176px; }
        .pilha-mesa .carta:nth-child(10) { top: 198px; }
        .pilha-mesa .carta:nth-child(11) { top: 220px; }
        .pilha-mesa .carta:nth-child(12) { top: 242px; }
        .pilha-mesa .carta:nth-child(n+13) { top: 264px; }

    </style>
</head>
<body>

    <h1>♠️ Solitário Jucabel</h1>
    <button onclick="reiniciarJogo()">Novo Jogo</button>

    <div id="jogo">
        <div class="area-superior">
            <div id="estoque" class="espaco-vazio" onclick="pedirCarta()">🔄</div>
            <div id="descarte"></div>
            <div style="grid-column: span 1;"></div> <div id="fundacao-0" class="fundacao espaco-vazio" onclick="tratarCliqueEspaco('fundacao', 0)">A</div>
            <div id="fundacao-1" class="fundacao espaco-vazio" onclick="tratarCliqueEspaco('fundacao', 1)">A</div>
            <div id="fundacao-2" class="fundacao espaco-vazio" onclick="tratarCliqueEspaco('fundacao', 2)">A</div>
            <div id="fundacao-3" class="fundacao espaco-vazio" onclick="tratarCliqueEspaco('fundacao', 3)">A</div>
        </div>

        <div id="mesa-0" class="pilha-mesa" onclick="tratarCliqueEspaco('mesa', 0)"></div>
        <div id="mesa-1" class="pilha-mesa" onclick="tratarCliqueEspaco('mesa', 1)"></div>
        <div id="mesa-2" class="pilha-mesa" onclick="tratarCliqueEspaco('mesa', 2)"></div>
        <div id="mesa-3" class="pilha-mesa" onclick="tratarCliqueEspaco('mesa', 3)"></div>
        <div id="mesa-4" class="pilha-mesa" onclick="tratarCliqueEspaco('mesa', 4)"></div>
        <div id="mesa-5" class="pilha-mesa" onclick="tratarCliqueEspaco('mesa', 5)"></div>
        <div id="mesa-6" class="pilha-mesa" onclick="tratarCliqueEspaco('mesa', 6)"></div>
    </div>

    <script>
        const naipes = ['♠', '♥', '♦', '♣'];
        const valores = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
        let estadoJogo = { estoque: [], descarte: [], fundacoes: [[], [], [], []], mesa: [[], [], [], [], [], [], []] };
        let cartaSelecionada = null;

        function criarBaralho() {
            let baralho = [];
            for (let naipe of naipes) {
                for (let i = 0; i < valores.length; i++) {
                    baralho.push({ valor: valores[i], naipe: naipe, peso: i + 1, cor: (naipe === '♥' || naipe === '♦') ? 'vermelha' : 'preta', faceParaCima: false });
                }
            }
            return baralho;
        }

        function embaralhar(array) {
            for (let i = array.length - 1; i > 0; i--) {
                const j = Math.floor(Math.random() * (i + 1));
                [array[i], array[j]] = [array[j], array[i]];
            }
        }

        function distribuirCartas() {
            let baralho = criarBaralho();
            embaralhar(baralho);
            estadoJogo = { estoque: [], descarte: [], fundacoes: [[], [], [], []], mesa: [[], [], [], [], [], [], []] };
            for (let i = 0; i < 7; i++) {
                for (let j = 0; j <= i; j++) {
                    let carta = baralho.pop();
                    if (j === i) carta.faceParaCima = true;
                    estadoJogo.mesa[i].push(carta);
                }
            }
            estadoJogo.estoque = baralho;
        }

        function criarCardElement(carta, local, pilhaIndex, cartaIndex) {
            const div = document.createElement('div');
            div.className = `carta ${carta.cor} ${carta.faceParaCima ? '' : 'verso'}`;
            if (carta.faceParaCima) {
                div.innerHTML = `<div class="topo"><div>${carta.valor}</div><div>${carta.naipe}</div></div><div class="base"><div>${carta.valor}</div><div>${carta.naipe}</div></div>`;
                div.onclick = (e) => { e.stopPropagation(); tratarCliqueCarta(carta, local, pilhaIndex, cartaIndex); };
            }
            if (cartaSelecionada && cartaSelecionada.local === local && cartaSelecionada.pilhaIndex === pilhaIndex && cartaSelecionada.cartaIndex === cartaIndex) {
                div.classList.add('selecionada');
            }
            return div;
        }

        function renderizar() {
            document.getElementById('estoque').innerHTML = estadoJogo.estoque.length > 0 ? '' : '🔄';
            if(estadoJogo.estoque.length > 0) document.getElementById('estoque').appendChild(criarCardElement({ faceParaCima: false }, 'estoque', 0, 0));
            document.getElementById('descarte').innerHTML = '';
            if (estadoJogo.descarte.length > 0) {
                const ultima = estadoJogo.descarte[estadoJogo.descarte.length - 1];
                document.getElementById('descarte').appendChild(criarCardElement(ultima, 'descarte', 0, estadoJogo.descarte.length - 1));
            }
            for (let i = 0; i < 4; i++) {
                const div = document.getElementById(`fundacao-${i}`);
                div.innerHTML = 'A';
                if (estadoJogo.fundacoes[i].length > 0) {
                    div.innerHTML = '';
                    div.appendChild(criarCardElement(estadoJogo.fundacoes[i][estadoJogo.fundacoes[i].length - 1], 'fundacao', i, estadoJogo.fundacoes[i].length - 1));
                }
            }
            for (let i = 0; i < 7; i++) {
                const div = document.getElementById(`mesa-${i}`);
                div.innerHTML = '';
                estadoJogo.mesa[i].forEach((carta, j) => div.appendChild(criarCardElement(carta, 'mesa', i, j)));
            }
        }

        function reiniciarJogo() { distribuirCartas(); cartaSelecionada = null; renderizar(); }

        function pedirCarta() {
            cartaSelecionada = null;
            if (estadoJogo.estoque.length > 0) {
                let carta = estadoJogo.estoque.pop();
                carta.faceParaCima = true;
                estadoJogo.descarte.push(carta);
            } else if (estadoJogo.descarte.length > 0) {
                estadoJogo.estoque = estadoJogo.descarte.reverse().map(c => { c.faceParaCima = false; return c; });
                estadoJogo.descarte = [];
            }
            renderizar();
        }

        function tratarCliqueCarta(carta, local, pilhaIndex, cartaIndex) {
            if (!cartaSelecionada) {
                if (carta.faceParaCima) cartaSelecionada = { carta, local, pilhaIndex, cartaIndex };
            } else {
                if (local === 'mesa') tentarMoverParaMesa(pilhaIndex);
                else if (local === 'fundacao') tentarMoverParaFundacao(pilhaIndex);
                cartaSelecionada = null;
            }
            renderizar();
        }

        function tratarCliqueEspaco(tipo, index) {
            if (!cartaSelecionada) return;
            if (tipo === 'mesa') tentarMoverParaMesa(index);
            else if (tipo === 'fundacao') tentarMoverParaFundacao(index);
            cartaSelecionada = null;
            renderizar();
        }

        function tentarMoverParaMesa(destinoIndex) {
            const { carta: orig, pilhaIndex: origPilha, cartaIndex: origCarta } = cartaSelecionada;
            const pilhaDest = estadoJogo.mesa[destinoIndex];
            const dest = pilhaDest.length > 0 ? pilhaDest[pilhaDest.length - 1] : null;
            let valido = false;
            if (!dest) { if (orig.valor === 'K') valido = true; }
            else { if (orig.cor !== dest.cor && orig.peso === dest.peso - 1) valido = true; }
            if (valido) executarMovimento(destinoIndex, 'mesa');
        }

        function tentarMoverParaFundacao(destinoIndex) {
            const { carta: orig, local, pilhaIndex: origPilha, cartaIndex: origCarta } = cartaSelecionada;
            if (local === 'mesa' && origCarta !== estadoJogo.mesa[origPilha].length - 1) return;
            const pilhaDest = estadoJogo.fundacoes[destinoIndex];
            const dest = pilhaDest.length > 0 ? pilhaDest[pilhaDest.length - 1] : null;
            let valido = false;
            if (!dest) { if (orig.valor === 'A') valido = true; }
            else { if (orig.naipe === dest.naipe && orig.peso === dest.peso + 1) valido = true; }
            if (valido) executarMovimento(destinoIndex, 'fundacao');
        }

        function executarMovimento(destIdx, tipoDest) {
            const { local, pilhaIndex: origPilha, cartaIndex: origCarta } = cartaSelecionada;
            let cartas = [];
            if (local === 'descarte') cartas = [estadoJogo.descarte.pop()];
            else if (local === 'fundacao') cartas = [estadoJogo.fundacoes[origPilha].pop()];
            else if (local === 'mesa') cartas = estadoJogo.mesa[origPilha].splice(origCarta);
            if (tipoDest === 'mesa') estadoJogo.mesa[destIdx] = estadoJogo.mesa[destIdx].concat(cartas);
            else estadoJogo.fundacoes[destIdx] = estadoJogo.fundacoes[destIdx].concat(cartas);
            if (local === 'mesa' && estadoJogo.mesa[origPilha].length > 0) estadoJogo.mesa[origPilha][estadoJogo.mesa[origPilha].length - 1].faceParaCima = true;
            checkVitoria();
        }

        function checkVitoria() {
            if (estadoJogo.fundacoes.reduce((s, p) => s + p.length, 0) === 52) {
                renderizar();
                setTimeout(() => alert('🎉 Parabéns Jucabel, você venceu!'), 100);
            }
        }
        reiniciarJogo();
    </script>
</body>
</html>

