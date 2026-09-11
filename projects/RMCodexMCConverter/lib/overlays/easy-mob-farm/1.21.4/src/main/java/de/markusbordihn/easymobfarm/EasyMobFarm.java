package de.markusbordihn.easymobfarm;

import de.markusbordihn.easymobfarm.block.ModBlocks;
import de.markusbordihn.easymobfarm.compat.CompatHandler;
import de.markusbordihn.easymobfarm.compat.CompatManager;
import de.markusbordihn.easymobfarm.component.ModDataComponents;
import de.markusbordihn.easymobfarm.config.Config;
import de.markusbordihn.easymobfarm.debug.DebugManager;
import de.markusbordihn.easymobfarm.experience.ExperienceManager;
import de.markusbordihn.easymobfarm.experience.ModExperienceManager;
import de.markusbordihn.easymobfarm.item.ModBlockItems;
import de.markusbordihn.easymobfarm.item.ModItems;
import de.markusbordihn.easymobfarm.menu.ModMenuTypes;
import net.neoforged.api.distmarker.Dist;
import net.neoforged.bus.api.IEventBus;
import net.neoforged.fml.common.Mod;
import net.neoforged.fml.loading.FMLEnvironment;
import net.neoforged.fml.loading.FMLLoader;
import net.neoforged.fml.loading.FMLPaths;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

@Mod("easy_mob_farm")
public class EasyMobFarm {
   private static final Logger log = LogManager.getLogger("Easy Mob Farm");

   public EasyMobFarm(IEventBus modEventBus) {
      log.info("Initializing {} (NeoForge) ...", "Easy Mob Farm");
      log.info("{} Debug Manager ...", "Register Easy Mob Farm");
      if (!FMLLoader.getCurrent().isProduction()) {
         DebugManager.setDevelopmentEnvironment(true);
      }

      DebugManager.checkForDebugLogging("Easy Mob Farm");
      log.info("{} Constants ...", "Register Easy Mob Farm");
      Constants.GAME_DIR = FMLPaths.GAMEDIR.get();
      Constants.CONFIG_DIR = FMLPaths.CONFIGDIR.get();
      log.info("{} Configuration ...", "Register Easy Mob Farm");
      Config.register(FMLEnvironment.getDist() == Dist.DEDICATED_SERVER);
      log.info("{} Compatibility Handler ...", "Register Easy Mob Farm");
      CompatManager.registerCompatHandler(new CompatHandler());
      log.info("{} Experience Manager ...", "Register Easy Mob Farm");
      ExperienceManager.registerExperienceManager(new ModExperienceManager());
      log.info("{} Blocks ...", "Register Easy Mob Farm");
      ModBlocks.BLOCKS.register(modEventBus);
      log.info("{} Blocks Entities ...", "Register Easy Mob Farm");
      ModBlocks.BLOCK_ENTITY_TYPES.register(modEventBus);
      log.info("{} Block Items ...", "Register Easy Mob Farm");
      ModBlockItems.ITEMS.register(modEventBus);
      log.info("{} Items ...", "Register Easy Mob Farm");
      ModItems.ITEMS.register(modEventBus);
      log.info("{} Menu Types ...", "Register Easy Mob Farm");
      ModMenuTypes.MENU_TYPES.register(modEventBus);
      log.info("{} Mod Data Components ...", "Register Easy Mob Farm");
      ModDataComponents.DATA_COMPONENTS.register(modEventBus);
   }
}
