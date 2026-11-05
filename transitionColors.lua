-- Per-frame color transform for native images, label text AND stroke.
-- Apply to original immutable palette each frame, not prior output.
local colors = {}
local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end
local function round(v) return math.floor(v + .5) end

function colors.apply(original, frame)
    assert(type(original) == 'table', 'original palette required')
    assert(type(frame) == 'table', 'transition sample required')
    local fade = clamp(tonumber(frame.alpha) or 0, 0, 1)
    local whitening = clamp(tonumber(frame.whiten) or 0, 0, 1)
    local result = {}
    for _, name in ipairs({'red', 'green', 'blue'}) do
        local source = clamp(tonumber(original[name]) or 255, 0, 255)
        result[name] = round(source + (255 - source) * whitening)
    end
    result.alpha = round(clamp(tonumber(original.alpha) or 255, 0, 255) * fade)
    return result
end

function colors.label(text_color, stroke_color, frame)
    return colors.apply(text_color, frame), colors.apply(stroke_color, frame)
end

return colors
