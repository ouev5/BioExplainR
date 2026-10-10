const http = require('node:http');
const fs = require('node:fs');
const root = 'research/results/model';
const saved = fs.readdirSync(root).filter(n => n.endsWith('__facts_only__1__prompt.json')).map(name => ({
  prompt: JSON.parse(fs.readFileSync(`${root}/${name}`, 'utf8')),
  response: JSON.parse(fs.readFileSync(`${root}/${name.replace('__prompt.json', '.json')}`, 'utf8')).response
}));
http.createServer((req, res) => {
  let raw = '';
  req.on('data', chunk => raw += chunk);
  req.on('end', () => {
    let body;
    try { body = JSON.parse(raw); } catch { res.writeHead(400); res.end(); return; }
    const text = body.messages?.filter(m => m.role === 'user').map(m => typeof m.content === 'string' ? m.content : m.content?.map(c => c.text || '').join('')).join('\n');
    const match = saved.find(s => text === s.prompt.user);
    if (!match || body.stream) { res.writeHead(422); res.end(JSON.stringify({error: {message: 'Unknown saved prompt or streaming request'}})); return; }
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ id: 'local-replay', object: 'chat.completion', model: 'saved-response-replay',
      choices: [{index: 0, message: {role: 'assistant', content: match.response.text}, finish_reason: 'stop'}],
      usage: {prompt_tokens: 0, completion_tokens: 0, total_tokens: 0}}));
  });
}).listen(18979, '127.0.0.1', () => console.log('Local replay only: 127.0.0.1:18979'));
