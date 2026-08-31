if SERVER and resource and resource.AddFile then
    local function addTree(root)
        local files, directories = file.Find(root .. "/*", "GAME")

        for _, name in ipairs(files or {}) do
            resource.AddFile(root .. "/" .. name)
        end

        for _, name in ipairs(directories or {}) do
            addTree(root .. "/" .. name)
        end
    end

    resource.AddFile("resource/fonts/ft_tfa_inter_regular.ttf")
    resource.AddFile("resource/fonts/ft_tfa_inter_medium.ttf")
    resource.AddFile("resource/fonts/ft_tfa_inter_semibold.ttf")
    resource.AddFile("resource/fonts/ft_tfa_inter_bold.ttf")
    resource.AddFile("resource/fonts/ft_arc9_venrynsans.ttf")
    resource.AddFile("resource/fonts/ft_arc9_venrynsans_medium.ttf")
    resource.AddFile("resource/fonts/ft_arc9_venrynsans_semibold.ttf")
    resource.AddFile("resource/fonts/ft_arc9_venrynsans_bold.ttf")
    resource.AddFile("resource/fonts/ft_arccw_bahnschrift.ttf")
    resource.AddFile("resource/fonts/ft_mw_8mm6z.ttf")
    resource.AddFile("resource/fonts/ft_mw_biosansw05_light.ttf")
    resource.AddFile("resource/fonts/ft_mw_conduit_itc.ttf")
    resource.AddFile("resource/fonts/ft_tacrp_myriad_pro.ttf")
    addTree("materials/ft_base/providers")
end
