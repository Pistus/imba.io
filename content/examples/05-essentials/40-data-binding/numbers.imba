css body p:4
css input[type=number] d:block p:1 c:gray8 bw:1 bc:gray4 radius:2px
css input[type=range] d:block c:gray8
css div d:block mt:1 c:gray7

let number = 1
let object = {number: 2}

imba.mount do <div>
	<div[d:grid gtc:1fr 3fr 1fr 3fr gap:2]>
		<input type='number' min=0 max=10 bind=number>
		<input type='range' min=0 max=10 bind=number>
		<input type='number' min=0 max=10 bind=object.number>
		<input type='range' min=0 max=10 bind=object.number>
	<div.field> "{number} + {object.number} = {number + object.number}"