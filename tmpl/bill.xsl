<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:strip-space elements="td th" />
<xsl:template match="/">
<html lang="ru">
<head>
<title>Skybill <xsl:text disable-output-escaping="yes">&amp;mdash;</xsl:text> отчёт по трафику</title>
<link rel='stylesheet' type='text/css' href='/bill.css?' />
</head>
<body>
<table width='100%' border='0' cellspacing='0' cellpadding='0'>
	<tr>
		<td colspan='3' align='center' class='subbody'>
			Сегодня: <xsl:value-of select='bill/head/@date' />
			<br />
			За месяц: 
			<xsl:call-template name='bytes'>
				<xsl:with-param name='acct' select='bill/head/@monthly-bytes' />
			</xsl:call-template>
		</td>
	</tr>
	<tr>
		<xsl:apply-templates />
	<tr>
	</tr>
		<td colspan='3' align='center' class='subbody'>
			За год:
			<xsl:call-template name='bytes'>
				<xsl:with-param name='acct' select='bill/head/@yearly-bytes' />
			</xsl:call-template>
			<br />
			Время составления:
			<xsl:value-of select='format-number(bill/@forming-time, "0.##" )' /> сек
		</td>
	</tr>
</table>
<div align='center'><xsl:text disable-output-escaping="yes">&amp;copy;</xsl:text> <a href="http://vereshagin.org">Peter Vereshagin</a> <xsl:text disable-output-escaping="yes">&amp;</xsl:text>lt;peter@vereshagin.org<xsl:text disable-output-escaping="yes">&amp;gt;</xsl:text>.<br /><a href='http://skybill.sf.net'>Skybill</a> is a free open source software distributed under the terms of <a href='http://www.opensource.org/licenses/bsd-license.php'>BSD License</a></div>
</body></html>
</xsl:template>
<xsl:template match='yesterday'>
	<xsl:call-template name='daybar'>
		<xsl:with-param name='dayname'>
			Вчера
		</xsl:with-param>
	</xsl:call-template>
</xsl:template>
<xsl:template match='today'>
	<xsl:call-template name='daybar'>
		<xsl:with-param name='dayname'>
			Сегодня 
		</xsl:with-param>
	</xsl:call-template>
</xsl:template>
<xsl:template name='daybar'>
	<xsl:param name='dayname' ></xsl:param>
	<td width='20%' valign='top'>
		<table width='100%' border='0' cellspacing='0' cellpadding='0'>
			<thead>
				<tr>
					<th width='100%'>
						<xsl:value-of select="$dayname" />:  
						<xsl:value-of select="@date" />
						<br />
						<xsl:call-template name='bytes'>
								<xsl:with-param name='acct'>
									<xsl:value-of select='@bytes' />
								</xsl:with-param>
						</xsl:call-template>
					</th>
				</tr>
			</thead>
			<tbody>
				<tr>
					<td width='100%'>
						<table width='100%' border='1' cellspacing='0' cellpadding='0'>
							<thead>
								<tr align='center'>
									<th width='100%'>Исходящие
									</th>
								</tr>
							</thead>
							<tbody>
								<tr align='center'>
									<td>
										<table width='100%' border='0' cellspacing='0' cellpadding='0'>
											<tr align='center'>
												<td>
										Клиентов: <xsl:value-of select='@internal-clients' />
										<br />
										Байт: 
											<xsl:call-template name='bytes'>
												<xsl:with-param name='acct'>
													<xsl:value-of select='@internal-bytes' />
												</xsl:with-param>
											</xsl:call-template>
												</td>
											</tr>
											<tr>
												<td>
													<table width='100%' border='0' cellspacing='0' cellpadding='0'>
														<xsl:for-each select='internals-rating/rate'>
															<xsl:call-template name='ip-chart-row'>
																<xsl:with-param name='max' select='../rate[position()=1]/@bytes' />
															</xsl:call-template>
														</xsl:for-each>
													</table>
												</td>
											</tr>
											<tr align='center'>
												<td>
													Портов: <xsl:value-of select='@internal-ports' />
												</td>
											</tr>
											<tr>
												<td>
													<table width='100%' border='0' cellspacing='0' cellpadding='0'>
														<xsl:for-each select='internal-ports-rating/rate'>
															<xsl:call-template name='port-chart-row' >
																<xsl:with-param name='max' select='../rate[position()=1]/@bytes' />
															</xsl:call-template>
														</xsl:for-each>
													</table>
												</td>
											</tr>
										</table>
									</td>
								</tr>
							</tbody>
						</table>
					</td>
				</tr>
				<tr>
					<td>
						<table width='100%' border='1' cellspacing='0' cellpadding='0'>
							<thead>
								<tr>
									<th width='100%'>Входящие
									</th>
								</tr>
							</thead>
							<tbody>
								<tr>
									<td width='100%'>
										<table width='100%' border='0' cellspacing='0' cellpadding='0'>
											<tr>
												<td width='100%'>
													<table width='100%' border='0' cellspacing='0' cellpadding='0'>
														<tr align='center'>
															<td>
																Хостов: <xsl:value-of select='@external-clients' />
																<br />
																Байт: 
																<xsl:call-template name='bytes'>
																	<xsl:with-param name='acct'>
																		<xsl:value-of select='@external-bytes' />
																	</xsl:with-param>
																</xsl:call-template>
															</td>
														</tr>
													</table>
												</td>
											</tr>
											<tr>
												<td>
													<table width='100%' border='0' cellspacing='0' cellpadding='0'>
														<xsl:for-each select='externals-rating/rate'>
															<xsl:call-template name='ip-chart-row' >
																<xsl:with-param name='with-whois' select='1' />
																<xsl:with-param name='max' select='../rate[position()=1]/@bytes' />
															</xsl:call-template>
														</xsl:for-each>
													</table>
												</td>
											</tr>
											<tr align='center'>
												<td>
													Портов: <xsl:value-of select='@external-ports' />
												</td>
											</tr>
											<tr>
												<td>
													<table width='100%' border='0' cellspacing='0' cellpadding='0'>
														<xsl:for-each select='external-ports-rating/rate'>
															<xsl:call-template name='port-chart-row' >
																<xsl:with-param name='max' select='../rate[position()=1]/@bytes' />
															</xsl:call-template>
														</xsl:for-each>
													</table>
												</td>
											</tr>
										</table>
									</td>
								</tr>
							</tbody>
						</table>
					</td>
				</tr>
			</tbody>
		</table>
	</td>
</xsl:template>
<xsl:template name='bytes'>
	<xsl:param name='acct'>0</xsl:param>
	<xsl:choose>
		<xsl:when test='$acct &gt; 1024*1024*1024'>
			<xsl:value-of select='format-number( $acct div 1024 div 1024 div 1024, ".##" )' /> G
		</xsl:when>
		<xsl:when test='($acct &lt; 1024*1024*1024) and ( $acct &gt; 1024*1024 )'>
			<xsl:value-of select='format-number( $acct div 1024 div 1024 , ".##" )' /> M
		</xsl:when>
		<xsl:when test='($acct &lt; 1024*1024) and ( $acct &gt; 1024 )'>
			<xsl:value-of select='format-number( $acct div 1024 , ".##" )' /> K
		</xsl:when>
		<xsl:otherwise>
			<xsl:number grouping-separator=" " grouping-size="3" value='$acct' />
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>
<xsl:template name='ip-chart-row'>
	<xsl:param name='max'>66000000</xsl:param>
	<xsl:param name='with-whois'>0</xsl:param>
	<xsl:variable name='width'>50</xsl:variable>
	<xsl:variable name='pict_name'>/img/blue.gif</xsl:variable>
	<xsl:variable name='pict_over_name'>/img/blue-green.gif</xsl:variable>
			<tr align='center'>
				<td align='right'>
					<a href='@href'>
						<xsl:call-template name='ip-anchor'>
							<xsl:with-param name='with-whois' select='$with-whois' />
							<xsl:with-param name='ip' select='@ip' />
						</xsl:call-template>
					</a>
				</td>
				<td align='left'>
					<a href='{@href}'>
						<nobr>
							<img alt='' height='10' border='0' width='{ format-number( @bytes*$width div $max, "##" )}'
								src='{$pict_name}' 
								onmouseover="this.src='{$pict_over_name}'" onmouseout="this.src='{$pict_name}'"
							/>
							(<xsl:call-template name='bytes'><xsl:with-param name='acct' select='@bytes' /></xsl:call-template>)
						</nobr>
					</a>
				</td>
			</tr>
</xsl:template>
<xsl:template name='ip-anchor'>
	<xsl:param name='with-whois'>0</xsl:param>
	<xsl:param name='ip'>0.0.0.0</xsl:param>
	<xsl:variable name='whois-href'>
		<xsl:call-template name='whois-url'>
			<xsl:with-param name='ip' select='$ip' />
		</xsl:call-template>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test='$with-whois != 0'>
			<a target='_blank' href='{$whois-href}'>
				<xsl:value-of select='$ip' />:
			</a>
		</xsl:when>
		<xsl:otherwise>
			<a target='_blank' href='file://{$ip}'>
				<xsl:value-of select='$ip' />:
			</a>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>
<xsl:template name='port-chart-row'>
	<xsl:param name='max'>66000000</xsl:param>
	<xsl:variable name='width'>50</xsl:variable>
	<xsl:variable name='pict_name'>/img/blue.gif</xsl:variable>
	<xsl:variable name='pict_over_name'>/img/blue-green.gif</xsl:variable>
			<tr align='center'>
				<td align='right'>
					<xsl:value-of select='@port' />:
				</td>
				<td align='left'>
					<nobr>
						<img alt='' height='10' border='0' width='{ format-number( @bytes*$width div $max, "##" )}' src='{$pict_name}' 
							onmouseover='this.src="{$pict_over_name}"' onmouseout='this.src="{$pict_name}"'
						/>
						(<xsl:call-template name='bytes'><xsl:with-param name='acct' select='@bytes' /></xsl:call-template>)
					</nobr>
				</td>
			</tr>
</xsl:template>
<xsl:template match='content'>
	<td width='60%' align='center' class='subbody'>
		<table border='0' width='100%' cellspacing='0' cellpadding='0'>
				<tr>
					<td width='50%'>&#160;
					</td>
					<td width='0'>
						<xsl:apply-templates />
					</td>
					<td width='50%'>&#160;
					</td>
				</tr>
		</table>
	</td>
</xsl:template>
<xsl:template match='daily-ports'>
	<xsl:variable name='pict_name'>/img/blue.gif</xsl:variable>
	<xsl:variable name='pict_over_name'>/img/blue-green.gif</xsl:variable>
	<xsl:variable name='width'>150</xsl:variable>
		<table border='0' width='100%' cellspacing='0' cellpadding='0'>
			<thead>
				<tr>
					<th align='center' colspan='4'>
						По портам
						<xsl:value-of select='../../query/option[attribute::name="src"]/@value' />
						->
						<xsl:value-of select='../../query/option[attribute::name="dst"]/@value' />
						за день 
						<xsl:value-of select='../../head/@d' />
					</th>
				</tr>
			</thead>
			<tbody>
				<xsl:for-each select='fromto'>
					<tr>
						<td width='0'>
							<xsl:value-of select='@src_port' />
						</td>
						<td width='0'>
								-&gt;
						</td>
						<td width='0'>
							<xsl:value-of select='@dest_port' />
						</td>
						<td width='100%'>
								<nobr>
									<img alt='' height='10' border='0' 
										width='{ format-number( @bytes*$width div ../fromto[position()=1]/@bytes, "##" )}' src='{$pict_name}' 
									/>
									(<xsl:call-template name='bytes'>
										<xsl:with-param name='acct' select='@bytes' />
									</xsl:call-template>)
								</nobr>
						</td>
					</tr>
				</xsl:for-each>
			</tbody>
		</table>
</xsl:template>
<xsl:template match='daily-addresses'>
	<xsl:variable name='pict_name'>/img/blue.gif</xsl:variable>
	<xsl:variable name='pict_over_name'>/img/blue-green.gif</xsl:variable>
	<xsl:variable name='width'>150</xsl:variable>
	<form action='{../../query/@action}' name='da' method="GET" enctype='application/x-www-form-urlencode'>
		<table border='0' width='100%' cellspacing='0' cellpadding='0'>
			<thead>
				<tr>
					<th align='center' colspan='4'>
						Откуда и куда за день 
						<xsl:value-of select='../../head/@d' />
						(топ <xsl:value-of select='../../head/@contents_amount' />):
					</th>
				</tr>
				<tr>
					<td align='center' colspan='4'>
						<xsl:for-each select='../../query/option'>
							<xsl:if test='@name != "p" and @name != "q"'>
								<input type='hidden' name='{@name}' value='{@value}' />
							</xsl:if>
						</xsl:for-each>
						<input type='hidden' name='q' value='da' />
						<select name='p' onchange='da.submit()'>
							<xsl:for-each select='page'>
								<xsl:choose>
									<xsl:when test='../../../query/option[attribute::name="q"]/@value="dd" 
																	and @option=(../../../query/option[attribute::name="p"]/@value)
									'>
										<option selected='yes' value='{@option}'>
											<xsl:value-of select='@option-label' />
										</option>
									</xsl:when>
									<xsl:otherwise>
										<option value='{@option}'>
											<xsl:value-of select='@option-label' />
										</option>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:for-each>
						</select>
						<input type='submit' value='Да' />
						из 
						<xsl:value-of select='@count'/>
					</td>
				</tr>
			</thead>
			<tbody>
				<xsl:for-each select='fromto'>
					<tr>
						<td width='0'>
							<xsl:call-template name='ip-anchor'>
								<xsl:with-param name='with-whois' select='1' />
								<xsl:with-param name='ip' select='@src' />
							</xsl:call-template>
						</td>
						<td width='0'>
							<nobr>
								-&gt;
							</nobr>
						</td>
						<td width='0'>
							<xsl:call-template name='ip-anchor'>
								<xsl:with-param name='ip' select='@dest' />
							</xsl:call-template>
						</td>
						<td width='100%'>
							<a href='{@href}'>
								<nobr>
									<img alt='' height='10' border='0' 
										width='{ format-number( @bytes*$width div ../fromto[position()=1]/@bytes, "##" )}' src='{$pict_name}' 
										onmouseover="this.src='{$pict_over_name}'" onmouseout="this.src='{$pict_name}'"
									/>
									(<xsl:call-template name='bytes'>
										<xsl:with-param name='acct' select='@bytes' />
									</xsl:call-template>)
								</nobr>
							</a>
						</td>
					</tr>
				</xsl:for-each>
			</tbody>
		</table>
	</form>
</xsl:template>
<xsl:template match='daily-sources'>
	<xsl:variable name='pict_name'>/img/blue.gif</xsl:variable>
	<xsl:variable name='pict_over_name'>/img/blue-green.gif</xsl:variable>
	<xsl:variable name='width'>150</xsl:variable>
	<form action='{../../query/@action}' name='sd' method="GET" enctype='application/x-www-form-urlencode'>
		<table border='0' width='100%' cellspacing='0' cellpadding='0'>
			<thead>
				<tr>
					<th align='center' colspan='4'>
						Источники за день 
						<xsl:value-of select='../../head/@d' />
						(топ <xsl:value-of select='../../head/@contents_amount' />):
					</th>
				</tr>
					<xsl:if test='string-length( @href-nodst ) &gt; 0' >
					<tr>
						<td align='center' colspan='2'>
							Выбран потребитель:
							<xsl:value-of select='../../query/option[attribute::name="dst"]/@value' />
							<a href='{@href-nodst}'>
								смотреть всех
							</a>
						</td>
					</tr>
				</xsl:if>
				<tr>
					<td align='center' colspan='4'>
						<xsl:for-each select='../../query/option'>
							<xsl:if test='@name != "p" and @name != "q"'>
								<input type='hidden' name='{@name}' value='{@value}' />
							</xsl:if>
						</xsl:for-each>
						<input type='hidden' name='q' value='sd' />
						<select name='p' onchange='sd.submit()'>
							<xsl:for-each select='page'>
								<xsl:choose>
									<xsl:when test='../../../query/option[attribute::name="q"]/@value="sd" 
																	and @option=(../../../query/option[attribute::name="p"]/@value)
									'>
										<option selected='yes' value='{@option}'>
											<xsl:value-of select='@option-label' />
										</option>
									</xsl:when>
									<xsl:otherwise>
										<option value='{@option}'>
											<xsl:value-of select='@option-label' />
										</option>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:for-each>
						</select>
						<input type='submit' value='Да' />
						из 
						<xsl:value-of select='@count'/>
					</td>
				</tr>
			</thead>
			<tbody>
			<xsl:for-each select='rate'>
				<xsl:variable name='whois-href'>
					<xsl:call-template name='whois-url'>
						<xsl:with-param name='ip' select='@ip' />
					</xsl:call-template>
				</xsl:variable>
				<tr>
					<td width='0'>
						<a target='_blank' href='{$whois-href}'>
							<xsl:value-of select='@ip' />
						</a>
					</td>
					<td width='100%'>
						<a href='{@href}'>
							<nobr>
								<img alt='' height='10' border='0' 
									width='{ format-number( @bytes*$width div ../rate[position()=1]/@bytes, "##" )}'
									src='{$pict_name}' 
									onmouseover="this.src='{$pict_over_name}'" onmouseout="this.src='{$pict_name}'"
								/>
								(<xsl:call-template name='bytes'>
									<xsl:with-param name='acct' select='@bytes' />
								</xsl:call-template>)
							</nobr>
						</a>
					</td>
				</tr>
			</xsl:for-each>
			</tbody>
		</table>
	</form>
</xsl:template>
<xsl:template match='daily-dests'>
	<xsl:variable name='pict_name'>/img/blue.gif</xsl:variable>
	<xsl:variable name='pict_over_name'>/img/blue-green.gif</xsl:variable>
	<xsl:variable name='width'>150</xsl:variable>
	<form action='{../../query/@action}' name='dd' method="GET" enctype='application/x-www-form-urlencode'>
		<table border='0' width='100%' cellspacing='0' cellpadding='0'>
			<thead>
				<tr>
					<th align='center' colspan='2'>
						Потребители за день 
							<xsl:value-of select='../../head/@d' />
						:
					</th>
				</tr>
				<xsl:if test='string-length( @href-nosrc ) &gt; 0' >
					<tr>
						<td align='center' colspan='2'>
							Выбран источник:
							<xsl:value-of select='../../query/option[attribute::name="src"]/@value' />
							<a href='{@href-nosrc}'>
								смотреть всех
							</a>
						</td>
					</tr>
				</xsl:if>
					<tr>
						<td align='center' colspan='2'>
							<xsl:for-each select='../../query/option'>
								<xsl:if test='@name != "p" and @name != "q"'>
									<input type='hidden' name='{@name}' value='{@value}' />
								</xsl:if>
							</xsl:for-each>
							<input type='hidden' name='q' value='dd' />
							<select name='p' onchange='dd.submit()'>
								<xsl:for-each select='page'>
									<xsl:choose>
										<xsl:when test='../../../query/option[attribute::name="q"]/@value="dd"
											and
											@option=(../../../query/option[attribute::name="p"]/@value)
										'>
											<option selected='yes' value='{@option}'>
												<xsl:value-of select='@option-label' />
											</option>
										</xsl:when>
										<xsl:otherwise>
											<option value='{@option}'>
												<xsl:value-of select='@option-label' />
											</option>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:for-each>
							</select>
							<input type='submit' value='Да' />
							из 
							<xsl:value-of select='@count'/>
						</td>
					</tr>
			</thead>
			<tbody>
				<xsl:for-each select='rate'>
					<tr>
						<td width='0'>
							<xsl:call-template name='ip-anchor'>
								<xsl:with-param name='ip' select='@ip' />
							</xsl:call-template>
						</td>
						<td width='100%'>
							<nobr>
								<a href='{@href}'>
									<img alt='' height='10' border='0' 
										width='{ format-number( @bytes*$width div ../rate[position()=1]/@bytes, "##" )}'
										src='{$pict_name}' 
										onmouseover="this.src='{$pict_over_name}'" onmouseout="this.src='{$pict_name}'"
									/>
									(<xsl:call-template name='bytes'>
										<xsl:with-param name='acct' select='@bytes' />
									</xsl:call-template>)
								</a>
							</nobr>
						</td>
					</tr>
				</xsl:for-each>
			</tbody>
		</table>
	</form>
</xsl:template>
<xsl:template match='monthly-dests'>
	<xsl:variable name='pict_name'>/img/blue.gif</xsl:variable>
	<xsl:variable name='pict_over_name'>/img/blue-green.gif</xsl:variable>
	<xsl:variable name='width'>150</xsl:variable>
	<form action='{../../query/@action}' name='ms' method="GET" enctype='application/x-www-form-urlencode'>
		<table border='0' width='100%' cellspacing='0' cellpadding='0'>
			<thead>
				<tr>
					<th align='center' colspan='2'>
						Потребители за месяц
							<xsl:value-of select='../../head/@my' />
					 	:
					</th>
				</tr>
				<xsl:if test='string-length( @href-nosrc ) &gt; 0' >
					<tr>
						<td align='center' colspan='2'>
							Выбран источник:
							<xsl:value-of select='../../query/option[attribute::name="src"]/@value' />
							<a href='{@href-nosrc}'>
								смотреть всех
							</a>
						</td>
					</tr>
				</xsl:if>
					<tr>
						<td align='center' colspan='2'>
							<xsl:for-each select='../../query/option'>
								<xsl:if test='@name != "p" and @name != "q"'>
									<input type='hidden' name='{@name}' value='{@value}' />
								</xsl:if>
							</xsl:for-each>
							<input type='hidden' name='q' value='ms' />
							<select name='p' onchange='ms.submit()'>
								<xsl:for-each select='page'>
									<xsl:choose>
										<xsl:when test='../../../query/option[attribute::name="q"]/@value="ms"
											and
											@option=(../../../query/option[attribute::name="p"]/@value)
										'>
											<option selected='yes' value='{@option}'>
												<xsl:value-of select='@option-label' />
											</option>
										</xsl:when>
										<xsl:otherwise>
											<option value='{@option}'>
												<xsl:value-of select='@option-label' />
											</option>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:for-each>
							</select>
							<input type='submit' value='Да' />
							из 
							<xsl:value-of select='@count'/>
						</td>
					</tr>
			</thead>
			<tbody>
				<xsl:for-each select='rate'>
					<tr>
						<td width='0'>
							<xsl:call-template name='ip-anchor'>
								<xsl:with-param name='ip' select='@ip' />
							</xsl:call-template>
						</td>
						<td width='100%'>
							<nobr>
								<a href='{@href}'>
									<img alt='' height='10' border='0' 
										width='{ format-number( @bytes*$width div ../rate[position()=1]/@bytes, "##" )}'
										src='{$pict_name}' 
										onmouseover="this.src='{$pict_over_name}'" onmouseout="this.src='{$pict_name}'"
									/>
									(<xsl:call-template name='bytes'>
										<xsl:with-param name='acct' select='@bytes' />
									</xsl:call-template>)
								</a>
							</nobr>
						</td>
					</tr>
				</xsl:for-each>
			</tbody>
		</table>
	</form>
</xsl:template>
<xsl:template match='monthly-sources'>
	<xsl:variable name='pict_name'>/img/blue.gif</xsl:variable>
	<xsl:variable name='pict_over_name'>/img/blue-green.gif</xsl:variable>
	<xsl:variable name='width'>150</xsl:variable>
	<form action='{../../query/@action}' name='sm' method="GET" enctype='application/x-www-form-urlencode'>
		<table border='0' width='100%' cellspacing='0' cellpadding='0'>
			<thead>
				<tr>
					<th align='center' colspan='2'>
						Источники трафика за месяц 
						<xsl:value-of select='../../head/@my' />
						(топ <xsl:value-of select='../../head/@contents_amount' />):
					</th>
				</tr>
				<xsl:if test='string-length( @href-nodst ) &gt; 0' > 
					<tr>
						<td align='center' colspan='2'>
							Выбран потребитель:
							<xsl:value-of select='../../query/option[attribute::name="dst"]/@value' />
							<a href='{@href-nodst}'>
								смотреть всех
							</a>
						</td>
					</tr>
				</xsl:if> 
				<tr>
					<td align='center' colspan='2'>
						<xsl:for-each select='../../query/option'>
							<xsl:if test='@name != "p" and @name != "q"'>
								<inpu type='hidden' name='{@name}' value='{@value}' />
							</xsl:if>
						</xsl:for-each>
						<input type='hidden' name='q' value='sm' />
						<select name='p' onchange='sm.submit()'>
							<xsl:for-each select='page'>
								<xsl:choose>
									<xsl:when test='../../../query/option[attribute::name="q"]/@value="sm"
										and
										@option=(../../../query/option[attribute::name="p"]/@value)
									'>
										<option selected='yes' value='{@option}'>
											<xsl:value-of select='@option-label' />
										</option>
									</xsl:when>
									<xsl:otherwise>
										<option value='{@option}'>
											<xsl:value-of select='@option-label' />
										</option>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:for-each>
						</select>
						<input type='submit' value='Да' />
						из 
						<xsl:value-of select='@count'/>
					</td>
				</tr>
			</thead>
			<tbody>
				<xsl:for-each select='rate'>
					<xsl:variable name='whois-href'>
						<xsl:call-template name='whois-url'>
							<xsl:with-param name='ip' select='@ip' />
						</xsl:call-template>
					</xsl:variable>
					<tr>
						<td width='0'>
							<a target='_blank' href='{$whois-href}'>
								<xsl:value-of select='@ip' />
							</a>
						</td>
						<td width='100%'>
							<a href='{@href}'>
								<nobr>
									<img alt='' height='10' border='0' 
										width='{ format-number( @bytes*$width div ../rate[position()=1]/@bytes, "##" )}' src='{$pict_name}' 
										onmouseover="this.src='{$pict_over_name}'" onmouseout="this.src='{$pict_name}'"
									/>
									(<xsl:call-template name='bytes'>
										<xsl:with-param name='acct' select='@bytes' />
									</xsl:call-template>)
								</nobr>
							</a>
						</td>
					</tr>
				</xsl:for-each>
			</tbody>
		</table>
	</form>
</xsl:template>
<xsl:template match='daily-bytes'>
	<xsl:variable name='pict_name'>/img/blue.gif</xsl:variable>
	<xsl:variable name='pict_over_name'>/img/blue-green.gif</xsl:variable>
	<xsl:variable name='width'>200</xsl:variable>
	<table border='0' width='100%' cellspacing='0' cellpadding='0'>
		<thead>
			<tr>
				<th align='center' colspan='2'>
					Трафик по дням:
				</th>
			</tr>
			<xsl:if test='string-length( @href-nodst ) &gt; 0' >
				<tr>
					<td align='center' colspan='2'>
						Выбран потребитель:
						<xsl:value-of select='../../query/option[attribute::name="dst"]/@value' />
						<a href='{@href-nodst}'>
							смотреть всех
						</a>
					</td>
				</tr>
			</xsl:if>
			<xsl:if test='string-length( @href-nosrc ) &gt; 0' >
				<tr>
					<td align='center' colspan='2'>
						Выбран источник:
						<xsl:value-of select='../../query/option[attribute::name="src"]/@value' />
						<a href='{@href-nosrc}'>
							смотреть всех
						</a>
					</td>
				</tr>
			</xsl:if>
		</thead>
		<tbody>
			<xsl:for-each select='rate'>
				<tr>
					<td width='20%'>
						<xsl:value-of select='@day' />
					</td>
					<td width='80%'>
						<nobr>
							<a href='{@href}'>
								<img alt='' height='10' border='0' 
									width='{ format-number( @bytes*$width div ../@max-bytes, "##" )}' src='{$pict_name}' 
									onmouseover="this.src='{$pict_over_name}'" onmouseout="this.src='{$pict_name}'"
								/>
								(<xsl:call-template name='bytes'>
									<xsl:with-param name='acct' select='@bytes' />
								</xsl:call-template>)
							</a>
						</nobr>
					</td>
				</tr>
			</xsl:for-each>
		</tbody>
	</table>
</xsl:template>
<xsl:template match='monthly-bytes'>
	<xsl:variable name='pict_name'>/img/blue.gif</xsl:variable>
	<xsl:variable name='pict_over_name'>/img/blue-green.gif</xsl:variable>
	<xsl:variable name='width'>200</xsl:variable>
	<table border='0' width='100%' cellspacing='0' cellpadding='0'>
		<thead>
			<tr>
				<th align='center' colspan='2'>
					Трафик по месяцам:
				</th>
			</tr>
			<xsl:if test='string-length( @href-nodst ) &gt; 0' > 
				<tr>
					<td align='center' colspan='2'>
						Выбран потребитель:
						<xsl:value-of select='../../query/option[attribute::name="dst"]/@value' />
						<a href='{@href-nodst}'>
							смотреть всех
						</a>
					</td>
				</tr>
			</xsl:if> 
			<xsl:if test='string-length( @href-nosrc ) &gt; 0' > 
				<tr>
					<td align='center' colspan='2'>
						Выбран источник:
						<xsl:value-of select='../../query/option[attribute::name="src"]/@value' />
						<a href='{@href-nosrc}'>
							смотреть всех
						</a>
					</td>
				</tr>
			</xsl:if> 
		</thead>
		<tbody>
			<xsl:for-each select='rate'>
				<tr>
					<td width='20%'>
						<xsl:value-of select='@month' />/<xsl:value-of select='@year' />
					</td>
					<td width='80%'>
						<nobr>
							<a href='{@href}'>
								<img alt='' height='10' border='0' 
									width='{ format-number( @bytes*$width div ../@max-bytes, "##" )}' src='{$pict_name}' 
									onmouseover="this.src='{$pict_over_name}'" onmouseout="this.src='{$pict_name}'"
								/>
								(<xsl:call-template name='bytes'>
									<xsl:with-param name='acct' select='@bytes' />
								</xsl:call-template>)
							</a>
						</nobr>
					</td>
				</tr>
			</xsl:for-each>
		</tbody>
	</table>
</xsl:template>
<xsl:template name='whois-url'>
	<xsl:param name='ip'></xsl:param>
		http://www.ripe.net/whois?form_type=simple&amp;full_query_string=&amp;searchtext=<xsl:value-of select='$ip'/>&amp;Advanced+search=Advanced+search
</xsl:template>
</xsl:stylesheet>
