function NPCInsp(tabName, paramName, arg1, arg2, arg3, arg4, arg5, arg6)
end

if getActivatedMods():contains("AUD") then
    function NPCInsp(tabName, paramName, arg1, arg2, arg3, arg4, arg5, arg6)
        AUD.insp(tabName, paramName, arg1, arg2, arg3, arg4, arg5, arg6)
    end
end
