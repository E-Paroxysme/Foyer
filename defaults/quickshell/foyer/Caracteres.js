// Géré par Foyer. Emojis et caractères spéciaux pour la recherche du hub
// (taper « : » puis un mot, ou Super + ;). Chaque ligne : [caractère, mots-clés].
// Les caractères (type "c") apparaissent aussi dans la recherche normale.
.pragma library

var caracteres = [
    ["œ", "oe e dans l o oeuf coeur soeur"], ["Œ", "oe majuscule"], ["æ", "ae"], ["Æ", "ae majuscule"],
    ["É", "e accent aigu majuscule e majuscule"], ["È", "e accent grave majuscule"], ["Ê", "e circonflexe majuscule"],
    ["À", "a accent grave majuscule a majuscule"], ["Ç", "c cedille majuscule"], ["Ù", "u accent grave majuscule"],
    ["Ô", "o circonflexe majuscule"], ["Î", "i circonflexe majuscule"], ["ë", "e trema"], ["ï", "i trema"], ["ÿ", "y trema"],
    ["«", "guillemets ouvrant francais"], ["»", "guillemets fermant francais"], ["« »", "guillemets francais paire"],
    ["“", "guillemets anglais ouvrant"], ["”", "guillemets anglais fermant"], ["’", "apostrophe typographique"],
    ["–", "tiret demi cadratin"], ["—", "tiret cadratin long"], ["…", "points de suspension trois points"],
    ["€", "euro monnaie"], ["£", "livre sterling"], ["$", "dollar"], ["°", "degre degres temperature"],
    ["²", "carre exposant 2 au carre"], ["³", "cube exposant 3"], ["¹", "exposant 1"], ["⁻¹", "exposant moins un inverse"],
    ["½", "demi un demi moitie"], ["¼", "quart"], ["¾", "trois quarts"], ["‰", "pour mille"],
    ["×", "multiplie fois multiplication"], ["÷", "divise division"], ["±", "plus ou moins"], ["≠", "different"],
    ["≈", "environ approximativement egal"], ["≤", "inferieur ou egal"], ["≥", "superieur ou egal"], ["∞", "infini"],
    ["√", "racine carree"], ["π", "pi"], ["Ω", "omega ohm resistance"], ["µ", "micro mu"], ["Δ", "delta variation"],
    ["α", "alpha"], ["β", "beta"], ["θ", "theta angle"], ["λ", "lambda longueur onde"], ["σ", "sigma"], ["Σ", "somme sigma majuscule"],
    ["ω", "omega minuscule pulsation"], ["φ", "phi dephasage"], ["η", "eta rendement"], ["ρ", "rho masse volumique"], ["τ", "tau constante de temps"],
    ["∫", "integrale"], ["∂", "derivee partielle"], ["∈", "appartient"], ["∀", "pour tout"], ["∃", "il existe"],
    ["→", "fleche droite"], ["←", "fleche gauche"], ["↑", "fleche haut"], ["↓", "fleche bas"], ["⇒", "implique fleche double"],
    ["⇔", "equivalent equivaut"], ["↔", "fleche double sens"], ["•", "puce point liste"], ["·", "point median inclusif"],
    ["✓", "coche valide oui"], ["✗", "croix faux non"], ["©", "copyright"], ["®", "marque deposee"], ["™", "trademark"],
    ["§", "paragraphe section"], ["¶", "pied de mouche"], ["†", "croix obel"], ["№", "numero"], ["⌀", "diametre"],
    ["←→", "fleches"], ["‽", "interrobang"], ["¿", "point interrogation inverse espagnol"], ["¡", "point exclamation inverse"],
    ["ñ", "n tilde espagnol"], ["ß", "eszett allemand"], ["ü", "u trema allemand"], ["ö", "o trema allemand"], ["ä", "a trema allemand"]
];

var emojis = [
    ["😀", "sourire content heureux"], ["😂", "rire larmes mdr"], ["🤣", "mort de rire"], ["😊", "sourire timide gentil"],
    ["😉", "clin d oeil"], ["😍", "amoureux coeur yeux"], ["😘", "bisou"], ["😎", "cool lunettes"], ["🤔", "reflexion hmm pense"],
    ["😅", "gene sueur ouf"], ["😇", "ange sage"], ["🙂", "sourire leger"], ["🙃", "a l envers ironie"], ["😐", "neutre"],
    ["😴", "dodo sommeil fatigue"], ["😢", "triste larme"], ["😭", "pleure"], ["😡", "colere enerve"], ["😱", "peur choc"],
    ["🤯", "explosion tete choque"], ["🥳", "fete anniversaire"], ["🤩", "etoiles waouh"], ["😬", "grimace oups"], ["🙄", "yeux au ciel"],
    ["🤓", "intello geek"], ["🤗", "calin"], ["🤐", "bouche cousue secret"], ["🥲", "sourire ému"], ["😷", "malade masque"],
    ["👍", "pouce ok d accord oui"], ["👎", "pouce bas non"], ["👏", "bravo applaudir"], ["🙌", "hourra"], ["🙏", "merci svp priere"],
    ["👋", "salut coucou bonjour main"], ["✌️", "paix victoire"], ["🤞", "croiser les doigts chance"], ["💪", "force muscle courage"],
    ["👌", "parfait ok"], ["👉", "doigt droite"], ["👈", "doigt gauche"], ["☝️", "doigt haut attention"], ["✍️", "ecrire"],
    ["❤️", "coeur amour rouge"], ["🧡", "coeur orange"], ["💛", "coeur jaune"], ["💚", "coeur vert"], ["💙", "coeur bleu"],
    ["💜", "coeur violet"], ["🖤", "coeur noir"], ["💔", "coeur brise"], ["✨", "etincelles magie"], ["🔥", "feu top"],
    ["⭐", "etoile"], ["🌟", "etoile brillante"], ["⚡", "eclair electricite"], ["💡", "idee ampoule"], ["🎉", "fete bravo confettis"],
    ["🎂", "gateau anniversaire"], ["🎁", "cadeau"], ["🏆", "trophee victoire"], ["🥇", "medaille or premier"], ["🎯", "cible objectif"],
    ["✅", "valide fait coche"], ["❌", "croix erreur non"], ["⚠️", "attention danger"], ["❓", "question"], ["❗", "exclamation important"],
    ["💯", "cent parfait"], ["🆗", "ok"], ["🔴", "rond rouge"], ["🟢", "rond vert"], ["🔵", "rond bleu"], ["🟠", "rond orange"],
    ["📚", "livres cours lecture"], ["📖", "livre ouvert"], ["📝", "note memo devoir"], ["✏️", "crayon"], ["🖊️", "stylo"],
    ["📏", "regle mesure"], ["📐", "equerre geometrie"], ["🧮", "boulier calcul"], ["🔬", "microscope science"], ["🧪", "eprouvette chimie"],
    ["🧲", "aimant"], ["⚙️", "engrenage reglage mecanique"], ["🔧", "cle outil"], ["🔩", "vis boulon"], ["🛠️", "outils"],
    ["🤖", "robot"], ["💻", "ordinateur portable"], ["🖥️", "ecran ordinateur"], ["⌨️", "clavier"], ["🖱️", "souris"],
    ["🔋", "batterie pile"], ["🔌", "prise electrique"], ["📡", "antenne satellite"], ["📱", "telephone portable"], ["☎️", "telephone fixe"],
    ["📧", "courriel mail"], ["📅", "calendrier date"], ["📌", "punaise epingle"], ["📎", "trombone"], ["🔒", "cadenas securite"],
    ["🔑", "cle mot de passe"], ["🗂️", "classeur dossier"], ["📁", "dossier"], ["📊", "graphique statistiques"], ["📈", "hausse courbe"],
    ["📉", "baisse"], ["🧠", "cerveau"], ["🎓", "diplome etudiant"], ["🏫", "ecole college lycee"], ["🚌", "bus"],
    ["🚗", "voiture"], ["🚲", "velo"], ["✈️", "avion voyage"], ["🚀", "fusee"], ["🏠", "maison"], ["☕", "cafe pause"],
    ["🍕", "pizza"], ["🍫", "chocolat"], ["🍎", "pomme"], ["🥐", "croissant"], ["🧀", "fromage"], ["🍷", "vin"],
    ["🍺", "biere"], ["🎵", "musique note"], ["🎮", "jeu manette"], ["🎲", "de jeu societe"], ["⚽", "foot ballon"],
    ["☀️", "soleil beau"], ["🌧️", "pluie"], ["❄️", "neige flocon froid"], ["🌈", "arc en ciel"], ["🌙", "lune nuit"],
    ["🌍", "terre monde planete"], ["🌱", "pousse plante ecologie"], ["🌳", "arbre"], ["🌸", "fleur"], ["🐱", "chat"],
    ["🐶", "chien"], ["🐟", "poisson aquarium"], ["🐢", "tortue lent"], ["🦄", "licorne"], ["👀", "yeux regarder"],
    ["⏰", "reveil heure"], ["⏳", "sablier attente"], ["🕐", "horloge"], ["🔔", "cloche notification"], ["📢", "annonce"]
];

// Recherche : mots qui commencent par la requête (déjà normalisée, sans accents).
function chercher(q, normaliser, avecEmojis, max) {
    var res = [];
    var mots = q.split(/\s+/).filter(function (m) { return m.length > 0; });
    function correspond(c) {
        var n = normaliser(c[1]).split(" ");
        return mots.every(function (m) { return n.some(function (w) { return w.indexOf(m) === 0; }); });
    }
    var sources = avecEmojis ? [emojis, caracteres] : [caracteres];
    for (var s = 0; s < sources.length; s++)
        for (var i = 0; i < sources[s].length && res.length < max; i++)
            if (mots.length === 0 || correspond(sources[s][i]))
                res.push({ car: sources[s][i][0], nom: sources[s][i][1].split(" ").slice(0, 3).join(" "), emoji: sources[s] === emojis });
    return res;
}
