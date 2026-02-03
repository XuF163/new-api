package service

import (
	"fmt"
	"strconv"
	"time"

	"github.com/QuantumNous/new-api/common"
	"github.com/QuantumNous/new-api/logger"
	"github.com/QuantumNous/new-api/model"
)

func todayYYYYMMDD() int {
	today, _ := strconv.Atoi(time.Now().Format("20060102"))
	return today
}

func debtFromQuota(quota int) int {
	if quota < 0 {
		return -quota
	}
	return 0
}

// CheckPostpaidDailyDebtLimit enforces a per-day maximum "new debt" increase for a user.
// The daily base is recorded in user.debt_daily_base on first quota update each day.
// Limit is measured in quota units. A limit of 0 means unlimited.
func CheckPostpaidDailyDebtLimit(userId int, currentQuota int, consumeQuota int) error {
	if consumeQuota <= 0 {
		return nil
	}
	if !common.PostpaidEnabled || common.PostpaidCreditDays <= 0 || common.PostpaidDailyDebtLimit <= 0 {
		return nil
	}

	nextQuota := currentQuota - consumeQuota
	if nextQuota >= 0 {
		return nil
	}

	state, err := model.GetUserDebtDailyState(userId)
	if err != nil {
		return err
	}

	today := todayYYYYMMDD()
	baseDebt := state.DebtDailyBase
	if state.DebtDailyDate != today {
		// Day has changed but user hasn't had any quota update today yet. Use current debt as base.
		baseDebt = debtFromQuota(currentQuota)
	}

	nextDebt := debtFromQuota(nextQuota)
	increase := nextDebt - baseDebt
	if increase <= 0 {
		return nil
	}
	if increase > common.PostpaidDailyDebtLimit {
		return fmt.Errorf(
			"单日赊账额度已达上限，请先充值或等待次日再使用（上限: %s, 今日新增欠费: %s）",
			logger.FormatQuota(common.PostpaidDailyDebtLimit),
			logger.FormatQuota(increase),
		)
	}
	return nil
}
