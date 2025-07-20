window.addEventListener('message', function(event) {
    if (event.data && event.data.action === 'openTablet') {
        document.getElementById('tablet').style.display = 'flex';
    }
});

document.getElementById('closeBtn').addEventListener('click', function() {
    document.getElementById('tablet').style.display = 'none';
    fetch(`https://${GetParentResourceName()}/closeTablet`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: '{}'
    });
});


document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        document.getElementById('tablet').style.display = 'none';
        fetch(`https://${GetParentResourceName()}/closeTablet`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: '{}'
        });
    }
});

document.getElementById('startJobBtn').addEventListener('click', function() {
    fetch(`https://${GetParentResourceName()}/startJob`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: '{}'
    });
    document.getElementById('tablet').style.display = 'none';
});


let scoreboardDiv = null;

function ensureScoreboard() {
    if (!scoreboardDiv) {
        scoreboardDiv = document.createElement('div');
        scoreboardDiv.id = 'jobdelivery-scoreboard';
        scoreboardDiv.style.position = 'fixed';
        scoreboardDiv.style.top = '220px';
        scoreboardDiv.style.right = '60px';
        scoreboardDiv.style.background = 'rgba(24,24,24,0.92)';
        scoreboardDiv.style.color = '#fff';
        scoreboardDiv.style.padding = '18px 44px 18px 44px'; 
        scoreboardDiv.style.borderRadius = '20px';
        scoreboardDiv.style.boxShadow = '0 2px 16px #0007';
        scoreboardDiv.style.fontSize = '1.45rem';
        scoreboardDiv.style.fontWeight = '700';
        scoreboardDiv.style.zIndex = '9999';
        scoreboardDiv.style.display = 'none';
        scoreboardDiv.style.minWidth = '200px';
        scoreboardDiv.style.minHeight = '0'; 
        scoreboardDiv.style.overflow = 'visible';
        document.body.appendChild(scoreboardDiv);
    }
}

window.addEventListener('message', function(event) {
    if (event.data && event.data.action === 'showScoreboard') {
        ensureScoreboard();
        scoreboardDiv.innerHTML =
            `<span style="margin-left:0;line-height:1.1;">ATM: <span id="scoreboard-delivered">${event.data.consegnati}</span> / <span id="scoreboard-total">${event.data.totali}</span></span>` +
            `<img src="img/tablet_bg.png" alt="tablet" style="position:absolute;left:-72px;top:50%;transform:translateY(-50%);width:96px;height:96px;object-fit:contain;opacity:0.93;pointer-events:none;user-select:none;z-index:10000;">`;
        scoreboardDiv.style.display = 'block';
    }
    if (event.data && event.data.action === 'updateScoreboard') {
        ensureScoreboard();
        document.getElementById('scoreboard-delivered').textContent = event.data.consegnati;
        document.getElementById('scoreboard-total').textContent = event.data.totali;
    }
    if (event.data && event.data.action === 'showDelivery') {
        ensureScoreboard();
        scoreboardDiv.innerHTML =
            `<span style="margin-left:0;line-height:1.1;color:#4CAF50;font-weight:bold;">Consegna il denaro</span>` +
            `<img src="img/tablet_bg.png" alt="tablet" style="position:absolute;left:-72px;top:50%;transform:translateY(-50%);width:96px;height:96px;object-fit:contain;opacity:0.93;pointer-events:none;user-select:none;z-index:10000;">`;
        scoreboardDiv.style.display = 'block';
    }
    if (event.data && event.data.action === 'hideScoreboard') {
        ensureScoreboard();
        scoreboardDiv.style.display = 'none';
    }
});
