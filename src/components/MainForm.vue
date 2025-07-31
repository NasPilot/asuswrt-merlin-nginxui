<template>
  <form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">
    <input type="hidden" name="current_page" :value="page" />
    <input type="hidden" name="next_page" :value="page" />
    <input type="hidden" name="group_id" value="" />
    <input type="hidden" name="modified" value="0" />
    <input type="hidden" name="action_mode" value="apply" />
    <input type="hidden" name="action_wait" value="5" />
    <input type="hidden" name="first_time" value="" />
    <input type="hidden" name="action_script" value="" />
    <input type="hidden" name="amng_custom" value="" />
    <table class="content" align="center" cellpadding="0" cellspacing="0">
      <tbody>
        <tr>
          <td width="17">&nbsp;</td>
          <td valign="top" width="202">
            <main-menu></main-menu>
            <sub-menu></sub-menu>
          </td>
          <td valign="top">
            <tab-menu></tab-menu>
            <table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
              <tbody>
                <tr>
                  <td valign="top">
                    <table width="760px" border="0" cellpadding="4" cellspacing="0" id="FormTitle" class="FormTitle">
                      <tbody>
                        <tr bgcolor="#4D595D">
                          <td valign="top">
                            <div class="formfontdesc">
                              <div>&nbsp;</div>
                              <div class="formfonttitle" style="text-align: left">Nginx UI v{{ version }}</div>
                              <div class="mode-group">
                                <div @click="set_mode('basic')" :class="{ active: mode === 'basic' }">{{ $t('labels.basic') }}</div>
                                <div @click="set_mode('advanced')" :class="{ active: mode === 'advanced' }">{{ $t('labels.advanced') }}</div>
                              </div>
                              <div id="formfontdesc" class="formfontdesc">{{ $t('labels.nginxui_desc') }}</div>
                              <div style="margin: 10px 0 10px 5px" class="splitLine"></div>
                              <service-status v-model:config="nginxConfig"></service-status>
                              <basic-mode v-if="isBasic" v-model:config="nginxConfig"></basic-mode>
                              <server-config v-if="isAdvanced" v-model:config="nginxConfig"></server-config>
                              <upstream-config v-if="isAdvanced" v-model:config="nginxConfig"></upstream-config>
                              <ssl-config v-if="isAdvanced" v-model:config="nginxConfig"></ssl-config>
                              <logs-viewer v-model:config="nginxConfig"></logs-viewer>
                              <div class="apply_gen">
                                <input class="button_gen" @click.prevent="apply_settings()" type="button" :value="$t('labels.apply')" />
                              </div>
                            </div>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </td>
                </tr>
              </tbody>
            </table>
          </td>
        </tr>
      </tbody>
    </table>
  </form>
</template>

<script lang="ts">
  import { defineComponent, ref, computed, inject } from 'vue';
  import { useI18n } from 'vue-i18n';
  import MainMenu from './asus/MainMenu.vue';
  import SubMenu from './asus/SubMenu.vue';
  import TabMenu from './asus/TabMenu.vue';
  import ServiceStatus from './ServiceStatus.vue';
  import BasicMode from './BasicMode.vue';
  import ServerConfig from './ServerConfig.vue';
  import UpstreamConfig from './UpstreamConfig.vue';
  import SslConfig from './SslConfig.vue';
  import LogsViewer from './LogsViewer.vue';
  import engine, { SubmitActions } from '@modules/Engine';

  export default defineComponent({
    name: 'MainForm',
    components: {
      MainMenu,
      SubMenu,
      TabMenu,
      ServiceStatus,
      BasicMode,
      ServerConfig,
      UpstreamConfig,
      SslConfig,
      LogsViewer
    },
    setup() {
      const { t } = useI18n();
      const nginxConfig = inject<Record<string, any>>('nginxConfig', {});
      const uiResponse = inject<Record<string, any>>('uiResponse', {});
      
      const mode = ref('basic');
      const version = ref('1.0.0');
      const page = ref('nginxui.asp');

      const isBasic = computed(() => mode.value === 'basic');
      const isAdvanced = computed(() => mode.value === 'advanced');

      const set_mode = (newMode: string) => {
        mode.value = newMode;
      };

      const apply_settings = async () => {
        try {
          await engine.submit(SubmitActions.applyConfig, nginxConfig, 5);
          // Show success message or handle response
        } catch (error) {
          console.error('Error applying settings:', error);
          // Show error message
        }
      };

      return {
        mode,
        version,
        page,
        nginxConfig,
        uiResponse,
        isBasic,
        isAdvanced,
        set_mode,
        apply_settings,
        t
      };
    }
  });
</script>

<style scoped>
  .mode-group {
    display: flex;
    gap: 10px;
    margin: 10px 0;
  }

  .mode-group div {
    background-color: #3A4A4F;
    border: 1px solid #5A6A6F;
    border-radius: 3px;
    color: #CCCCCC;
    cursor: pointer;
    font-size: 10px;
    padding: 5px 10px;
    text-align: center;
    transition: all 0.3s ease;
  }

  .mode-group div:hover {
    background-color: #475A5F;
    color: #FFFFFF;
  }

  .mode-group div.active {
    background-color: #6B8FA3;
    color: #FFFFFF;
    font-weight: bold;
  }

  .apply_gen {
    margin: 20px 0;
    text-align: center;
  }
</style>