-- PetBar geometry: one pure source for anchor, per-bar widths and local offsets.
-- Units are Windower UI pixels. Saved top-left anchor is not overwritten on resize.
local layout={}
local function clamp(n,lo,hi) return math.max(lo,math.min(hi,n)) end
local function round(n) return math.floor(n+.5) end
local function offset(s,key)
    local t=s.offsets and s.offsets[key] or {}
    return round(tonumber(t.x) or 0),round(tonumber(t.y) or 0)
end
local function width(s,key)
    local specific=tonumber(s[key..'_width']) or 0
    return specific>0 and specific or (tonumber(s.width) or 260)
end
function layout.calculate(settings,screen_w,screen_h)
    local s=settings
    local uw,uh=math.max(80,screen_w),math.max(60,screen_h)
    local scale=clamp(tonumber(s.scale) or 1,.65,2)
    local gap=round((tonumber(s.gap) or 6)*scale)
    local hp=math.max(16,round(width(s,'hp')*scale))
    local tp=math.max(16,round(width(s,'tp')*scale))
    if s.layout=='horizontal' then
        local available=math.max(32,uw-24-gap)
        local factor=math.min(1,available/(hp+tp))
        hp,tp=math.max(16,round(hp*factor)),math.max(16,round(tp*factor))
    else
        hp,tp=math.min(hp,math.max(16,uw-24)),math.min(tp,math.max(16,uw-24))
    end
    local horizontal=s.layout=='horizontal'
    local base_tp_x=horizontal and (hp+gap) or 0
    local base_tp_y=horizontal and 0 or 12+gap
    local total_w=horizontal and (hp+gap+tp) or math.max(hp,tp)
    local bars_h=horizontal and 12 or 24+gap
    local font=math.max(8,round((tonumber(s.font_size) or 13)*scale))
    local total_h=bars_h+font+8
    local oxh,oyh=offset(s,'hp')
    local oxt,oyt=offset(s,'tp')
    local oxn,oyn=offset(s,'name')
    local oxv,oyv=offset(s,'tptext')
    local name_x,name_y=3+oxn,bars_h+2+oyn
    local value_x,value_y=total_w-round(75*scale)+oxv,bars_h+2+oyv

    -- Recover the whole bar arrangement within screen bounds when feasible.
    -- Caption width is not knowable without Windows text metrics; reserve its
    -- approximate anchor and allow intentional offsets into unused UI space.
    local left=math.min(0,oxh,base_tp_x+oxt,name_x,value_x)
    local top=math.min(0,oyh,base_tp_y+oyt,name_y,value_y)
    local right=math.max(total_w,oxh+hp,base_tp_x+oxt+tp,
        name_x+round(110*scale),value_x+round(75*scale))
    local bottom=math.max(total_h,oyh+12,base_tp_y+oyt+12,
        name_y+font+2,value_y+font+2)
    local default_x=math.floor((uw-(right-left))/2)-left
    local default_y=math.max(0,math.floor(uh-145*scale))
    local saved_x=tonumber(s.pos and s.pos.x)
    local saved_y=tonumber(s.pos and s.pos.y)
    local x=round(saved_x and saved_x>=0 and saved_x or default_x)
    local y=round(saved_y and saved_y>=0 and saved_y or default_y)
    if right-left<=uw then x=clamp(x,-left,uw-right)
    else x=-left end
    if bottom-top<=uh then y=clamp(y,-top,uh-bottom)
    else y=-top end
    return {
        x=x,y=y,hp_width=hp,tp_width=tp,scale=scale,gap=gap,
        width=total_w,height=total_h,
        hp={x=x+oxh,y=y+oyh,width=hp},
        tp={x=x+base_tp_x+oxt,y=y+base_tp_y+oyt,width=tp},
        name={x=x+name_x,y=y+name_y},
        tptext={x=x+value_x,y=y+value_y},
        font=font,
    }
end
return layout
