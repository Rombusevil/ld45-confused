-- state
function chaman_state(stage, cb)
    local state,texts,ypos,frfg={},{},111,5
	local ypos=23
	add(texts, tutils({text="chaman's layer",centerx=true,y=8,fg=8,bg=0,bordered=true,shadowed=true,sh=2}))
	add(texts, tutils({text="press ❎ to restart", blink=true, on_time=15, centerx=true,y=110,fg=7,bg=1,bordered=false,shadowed=true,sh=0}))
	
	function to(t,ypos)return {text=t,centerx=true,shadowed=true,x=5,y=ypos,fg=7,sh=0} end

	if stage==1 then
		add(texts, tutils(to("hi billy. i know you want to",ypos))) ypos+=10
		add(texts, tutils(to("be human again. it's been so",ypos))) ypos+=10
		add(texts, tutils(to("long you probably don't",ypos))) ypos+=10
		add(texts, tutils(to("remember how that feels like.",ypos))) ypos+=20
		add(texts, tutils(to("search for bones in the trees",ypos))) ypos+=10
		add(texts, tutils(to("bring the bones to me and i'll",ypos))) ypos+=10
		add(texts, tutils(to("make you human again.",ypos))) ypos+=10
	elseif stage==2 then
		add(texts, tutils(to("good billy. you can be a ",ypos))) ypos+=10
		add(texts, tutils(to("skeleton now. bring me some",ypos))) ypos+=10
		add(texts, tutils(to("animal flesh and i'll give you",ypos))) ypos+=10
		add(texts, tutils(to("muscles.",ypos))) ypos+=10
	elseif stage==3 then
		add(texts, tutils(to("excellent! you're so close",ypos))) ypos+=10
		add(texts, tutils(to("billy. there's a final thing i",ypos))) ypos+=10
		add(texts, tutils(to("need... find your soul, billy.",ypos))) ypos+=10
		add(texts, tutils(to("and you'll be human again.",ypos))) ypos+=10
	elseif stage==4 then
		add(texts, tutils(to("yes, finally! you're a human.",ypos))) ypos+=10
		add(texts, tutils(to("you are the missing ingredient",ypos))) ypos+=10
		add(texts, tutils(to("for setting myself free from ",ypos))) ypos+=10
		add(texts, tutils(to("this haunted hut.",ypos))) ypos+=10
	end

	local enf=30
	state.update=function()
		cb.g.hut.hide=true
		
		if stage >= 4 then
			enf=80
		end

		if btnp(5) then
			sfx(3)
			if stage >= 4 then
				curstate=gfight_state()
			else 
				curstate=cb -- "X"
			end
		end
	end
	
	cls()
	
	local t=0
	local s = 64
	state.draw=function()
		t+=0.01
		camera(0,0)
		
		-- frame		
		rectfill(3-2,2, 128-4, 128-4, 7)
		rectfill(2-2,3, 128-3, 128-3, 7)
		
		rectfill(4-2,3, 128-5, 128-5, 0)
		rectfill(3-2,4, 128-4, 128-4, 0)
		
		rectfill(5-2,4, 128-6, 128-6, frfg)
		rectfill(4-2,5, 128-5, 128-5, frfg)
		
		
		local w = sin(t)*enf+50
        local h= sin(t)*enf+50
		sspr(16,8, 8,8, 64-(w/2),64-(h/2), w, h)

        -- title
        for t in all(texts) do
            t:draw()
        end
	end

	return state
end