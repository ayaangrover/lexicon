const express = require('express');
const app = express();
const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
puppeteer.use(StealthPlugin());

app.use(function (req, res, next) {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
    res.header('Access-Control-Allow-Headers', 'Content-Type');
    next();
});

const delay = ms => new Promise(resolve => setTimeout(resolve, ms));

const getQuizletSet = async (url) => {
    const browser = await puppeteer.launch({
        headless: true,
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-blink-features=AutomationControlled',
            '--window-size=1920,2700',
            '--lang=en-US,en;q=0.9',
            '--incognito'
        ]
    });
    const page = await browser.newPage();
    await page.setUserAgent(
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 13_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36'
    );
    await page.goto(url, {
        waitUntil: 'networkidle2',
        timeout: 30000
    });
    await page.waitForSelector('script[id=__NEXT_DATA__]');

    let raw = await page.$eval('script[id=__NEXT_DATA__]', el => el.textContent);
    let parsed = JSON.parse(raw).props.pageProps;
    let result = null;

    try {
        const { setTitle, canonicalUrl, socialImageUrl, dehydratedReduxStateKey } = parsed;
        if (!dehydratedReduxStateKey) {
            throw new Error('dehydratedReduxStateKey is missing');
        }

        const reduxState = JSON.parse(dehydratedReduxStateKey);
        console.log("Full Redux state:", JSON.stringify(reduxState, null, 2));
        console.log("Checking reduxState.studiableData:", JSON.stringify(reduxState.studiableData, null, 2));
        console.log("Checking reduxState.studyModesCommon:", JSON.stringify(reduxState.studyModesCommon, null, 2));

        let cards = [];
        if (reduxState.setPage && Array.isArray(reduxState.setPage.cards)) {
            console.log("Using reduxState.setPage.cards branch");
            cards = reduxState.setPage.cards;
        }
        else if (reduxState.studiableData && Array.isArray(reduxState.studiableData.studiableItems)) {
            console.log("Using reduxState.studiableData.studiableItems branch");
            cards = reduxState.studiableData.studiableItems.map(item => {
                const sides = item.cardSides || item.cardsides;
                if (sides && Array.isArray(sides)) {
                    const wordSide = sides.find(side => side.label === "word");
                    const definitionSide = sides.find(side => side.label === "definition");
                    const question = wordSide && wordSide.media && wordSide.media[0] ? wordSide.media[0].plainText : "";
                    const questionAudio = wordSide && wordSide.media && wordSide.media[0] ? wordSide.media[0].ttsUrl : "";
                    const answer = definitionSide && definitionSide.media && definitionSide.media[0] ? definitionSide.media[0].plainText : "";
                    const answerAudio = definitionSide && definitionSide.media && definitionSide.media[0] ? definitionSide.media[0].ttsUrl : "";
                    return { question, questionAudio, answer, answerAudio };
                } else {
                    return { question: "", questionAudio: "", answer: "", answerAudio: "" };
                }
            });
        }
        else if (reduxState.studyModesCommon &&
            reduxState.studyModesCommon.studiableData &&
            Array.isArray(reduxState.studyModesCommon.studiableData.studiableItems)) {
            console.log("Using reduxState.studyModesCommon.studiableData.studiableItems branch");
            console.log("Found studiableItems in reduxState:", JSON.stringify(reduxState.studyModesCommon.studiableData.studiableItems, null, 2));

            cards = reduxState.studyModesCommon.studiableData.studiableItems.map(item => {
                console.log("Processing item:", JSON.stringify(item, null, 2)); 
                const sides = item.cardSides || item.cardsides;
                if (sides && Array.isArray(sides)) {
                    const wordSide = sides.find(side => side.label === "word");
                    const definitionSide = sides.find(side => side.label === "definition");

                    const question = wordSide && wordSide.media && wordSide.media[0] ? wordSide.media[0].plainText : "";
                    const questionAudio = wordSide && wordSide.media && wordSide.media[0] ? wordSide.media[0].ttsUrl : "";
                    const answer = definitionSide && definitionSide.media && definitionSide.media[0] ? definitionSide.media[0].plainText : "";
                    const answerAudio = definitionSide && definitionSide.media && definitionSide.media[0] ? definitionSide.media[0].ttsUrl : "";

                    return { question, questionAudio, answer, answerAudio };
                } else {
                    console.warn("No valid sides found in item:", JSON.stringify(item, null, 2));
                    return { question: "", questionAudio: "", answer: "", answerAudio: "" };
                }
            });
        } else {
            console.warn('studiableItems branch missing or empty');
        }

        if (!Array.isArray(cards)) {
            console.warn('Cards is not an array');
        } else {
            console.log("Total cards extracted:", cards.length);
        }

        result = { url: canonicalUrl, socialImg: socialImageUrl, title: setTitle, cards: cards };
    } catch (error) {
        console.error("Error while processing Redux state:", error);
    }

    await browser.close();
    return result;
};

app.get('/status', (req, res) => {
    res.sendStatus(200);
});

app.get('/quizlet-set/:setId', async (req, res) => {
    const setId = req.params.setId;
    const url = `https://quizlet.com/${setId}`;
    try {
        const data = await getQuizletSet(url);
        await delay(500);  
        res.setHeader('Cache-Control', 'public, max-age=0');
        res.json(data);
    } catch (error) {
        console.error(error);
        res.status(500).send(error.message);
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
});
