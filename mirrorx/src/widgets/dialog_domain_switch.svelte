<script lang="ts">
	import { emit, listen, type UnlistenFn } from '@tauri-apps/api/event';
	import {
		invoke_config_domain_get,
		invoke_config_domain_update,
		invoke_signaling_connect
	} from '$lib/components/command';
	import { onDestroy, onMount } from 'svelte';
	import LL from '$lib/i18n/i18n-svelte';
	import { current_domain } from '$lib/components/stores';
	import { emitNotification } from '$lib/components/notification';

	let show: boolean = false;
	let unlisten_fn: UnlistenFn | null = null;
	let domain_id: number = 0;
	let domain_name: string = '';

	onMount(async () => {
		unlisten_fn = await listen<{ domain_id: number; domain_name: string }>('/dialog/domain_switch', (event) => {
			domain_id = event.payload.domain_id;
			domain_name = event.payload.domain_name;
			show = true;
		});
	});

	onDestroy(() => {
		if (unlisten_fn) {
			unlisten_fn();
		}
	});

	const yes = async () => {
		try {
			await invoke_config_domain_update(domain_id, 'set_primary');
			await invoke_signaling_connect(true);
			let new_primary_domain = await invoke_config_domain_get();
			current_domain.set(new_primary_domain);
			await emit('update_domains');
		} catch (error: any) {
			await emitNotification({
				level: 'error',
				title: 'Error',
				message: error.toString() as string
			});
		} finally {
			no();
		}
	};

	const no = () => {
		show = false;
	};
</script>

<slot>
	<input type="checkbox" id="dialog_switch_primary_domain" class="modal-toggle" checked={show} />
	<div class="modal">
		<div class="modal-box">
			<h3 class="text-lg font-bold">{$LL.Dialogs.DomainSwitch.Title()}</h3>
			<div class="py-4">
				{$LL.Dialogs.DomainSwitch.ContentPrefix()}
				<span class="font-bold">{domain_name}</span>
				{$LL.Dialogs.DomainSwitch.ContentSuffix()}
			</div>
			<div class="modal-action">
				<button class="btn" on:click={yes}>{$LL.DialogActions.Yes()}</button>
				<button class="btn" on:click={no}>{$LL.DialogActions.No()}</button>
			</div>
		</div>
	</div>
</slot>
