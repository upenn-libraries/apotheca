# frozen_string_literal: true

Time::DATE_FORMATS[:display] = ->(time) { time.localtime.strftime('%F %r') }
