-- ミッションの開始時に一度だけ呼ばれる
function missionStart()
	-- 必ず一つ以上SetMissionTypeすること！！（ないとミッションとして判定されない）
	-- SetMissionTypeに指定できるミッションの種類とパラメータ
	-- "Default"			0				// 特に条件がない場合
	-- "CollectRing"		リング数		// 指定数リングを取得
	-- "VsGhost"			0				// ゴースト対決
	-- "BoostMax"			ブースト倍率	// ブースト全開
	-- "RescueAnimals"		動物数			// 指定数動物解放
	-- "NpcRace"			0				// NPCとレース
	-- "CollectTreasure"	お宝数			// 宝探し(ナックルズ ssz200)
	-- "CollectChao"		チャオ数		// チャオ集め(クリーム sph100)
	-- "TimeLimit"			制限時間(秒)	// 時間制限
	-- "NoMiss"				0				// ノーミス
	-- "MakeTricks"			トリック数		// 規定回数トリックを決める
	-- "LiftingBoard"		0				// リフティング看板
	SetMissionType("TimeLimit", 760);

	SetResultTime(160, 460);
end

-- ミッションのリスタート時に呼ばれる
function missionRestart()
end

-- ミッションのプレイヤー初期化時に呼ばれる
function playerSetting()
	-- プレイヤスキル
	-- SetCustomizeSkill( スキル名 );
	-- "Barrier"			// バリア
	-- "FlameBarrier"		// フレイムバリア
	-- "AquaBarrier"		// アクアバリア
	-- "ThunderBarrier"		// サンダーバリア
	-- "SkateBoard"			// スケボー
	-- SetCustomizeSkill( "Barrier" );
	-- カオスエナジー
	-- "Max300"				// Max300
	-- "Max200"				// Max200
	-- "Max150"				// Max150
	-- SetChaosEnergy( 値 );
	-- SetChaosEnergy( "Max300" );
end
